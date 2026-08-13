import base64
import json
import os
import time
from contextlib import contextmanager
from decimal import Decimal
from typing import Any

import psycopg
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel, EmailStr, Field
from psycopg.rows import dict_row

SERVICE = os.getenv("SERVICE_NAME", "all")
DATABASE_URL = os.environ["DATABASE_URL"]
KEY = base64.urlsafe_b64decode(os.environ["IDENTITY_KEY_B64"])
if len(KEY) != 32:
    raise RuntimeError("IDENTITY_KEY_B64 debe decodificar exactamente 32 bytes")

app = FastAPI(title=f"Café Boreal - {SERVICE}", version="1.0.0")
Instrumentator().instrument(app).expose(app, include_in_schema=False)


@contextmanager
def db():
    with psycopg.connect(DATABASE_URL, row_factory=dict_row) as conn:
        yield conn


def encrypt_identity(value: str) -> str:
    nonce = os.urandom(12)
    encrypted = AESGCM(KEY).encrypt(nonce, value.encode(), b"cafe-boreal:identity:v1")
    return base64.b64encode(nonce + encrypted).decode()


def decrypt_identity(value: str) -> str:
    raw = base64.b64decode(value)
    return AESGCM(KEY).decrypt(raw[:12], raw[12:], b"cafe-boreal:identity:v1").decode()


class Product(BaseModel):
    nombre: str = Field(min_length=2, max_length=120)
    precio: Decimal = Field(gt=0)
    stock: int = Field(ge=0)
    descripcion: str = ""
    imagen: str = ""


class Customer(BaseModel):
    nombre: str = Field(min_length=2, max_length=120)
    email: EmailStr
    numero_identidad: str = Field(min_length=5, max_length=80)


class OrderItem(BaseModel):
    product_id: int
    cantidad: int = Field(gt=0)


class OrderIn(BaseModel):
    customer_id: int
    items: list[OrderItem] = Field(min_length=1)


def ensure(service: str):
    if SERVICE not in ("all", service):
        raise HTTPException(404, "Ruta no disponible en este servicio")


@app.get("/api/{service}/healthz")
def health(service: str):
    ensure(service)
    with db() as conn:
        conn.execute("SELECT 1")
    return {"status": "ok", "service": service}


@app.get("/api/catalog")
def products():
    ensure("catalog")
    with db() as conn:
        return conn.execute("SELECT * FROM products ORDER BY id").fetchall()


@app.post("/api/catalog", status_code=201)
def create_product(p: Product):
    ensure("catalog")
    with db() as conn:
        return conn.execute(
            "INSERT INTO products(nombre,precio,stock,descripcion,imagen) VALUES (%s,%s,%s,%s,%s) RETURNING *",
            (p.nombre, p.precio, p.stock, p.descripcion, p.imagen),
        ).fetchone()


@app.put("/api/catalog/{product_id}")
def update_product(product_id: int, p: Product):
    ensure("catalog")
    with db() as conn:
        row = conn.execute(
            "UPDATE products SET nombre=%s,precio=%s,stock=%s,descripcion=%s,imagen=%s WHERE id=%s RETURNING *",
            (p.nombre, p.precio, p.stock, p.descripcion, p.imagen, product_id),
        ).fetchone()
        if not row:
            raise HTTPException(404, "Producto no encontrado")
        return row


@app.delete("/api/catalog/{product_id}", status_code=204)
def delete_product(product_id: int):
    ensure("catalog")
    with db() as conn:
        if conn.execute("DELETE FROM products WHERE id=%s RETURNING id", (product_id,)).fetchone() is None:
            raise HTTPException(404, "Producto no encontrado")


def customer_public(row: dict[str, Any]) -> dict[str, Any]:
    row = dict(row)
    row["numero_identidad"] = decrypt_identity(row.pop("identity_ciphertext"))
    return row


@app.get("/api/customers")
def customers():
    ensure("customers")
    with db() as conn:
        return [customer_public(r) for r in conn.execute("SELECT * FROM customers ORDER BY id").fetchall()]


@app.post("/api/customers", status_code=201)
def create_customer(c: Customer):
    ensure("customers")
    with db() as conn:
        try:
            row = conn.execute(
                "INSERT INTO customers(nombre,email,identity_ciphertext,key_version) VALUES (%s,%s,%s,1) RETURNING *",
                (c.nombre, c.email, encrypt_identity(c.numero_identidad)),
            ).fetchone()
        except psycopg.errors.UniqueViolation:
            raise HTTPException(409, "El correo ya existe")
        return customer_public(row)


@app.put("/api/customers/{customer_id}")
def update_customer(customer_id: int, c: Customer):
    ensure("customers")
    with db() as conn:
        row = conn.execute(
            "UPDATE customers SET nombre=%s,email=%s,identity_ciphertext=%s WHERE id=%s RETURNING *",
            (c.nombre, c.email, encrypt_identity(c.numero_identidad), customer_id),
        ).fetchone()
        if not row:
            raise HTTPException(404, "Cliente no encontrado")
        return customer_public(row)


@app.delete("/api/customers/{customer_id}", status_code=204)
def delete_customer(customer_id: int):
    ensure("customers")
    with db() as conn:
        if conn.execute("DELETE FROM customers WHERE id=%s RETURNING id", (customer_id,)).fetchone() is None:
            raise HTTPException(404, "Cliente no encontrado")


@app.get("/api/orders")
def orders():
    ensure("orders")
    with db() as conn:
        return conn.execute("SELECT * FROM orders ORDER BY id DESC").fetchall()


@app.post("/api/orders", status_code=201)
def create_order(order: OrderIn):
    ensure("orders")
    with db() as conn:
        if conn.execute("SELECT 1 FROM customers WHERE id=%s", (order.customer_id,)).fetchone() is None:
            raise HTTPException(400, "Cliente inexistente")
        ids = [i.product_id for i in order.items]
        rows = conn.execute("SELECT id,nombre,precio,stock FROM products WHERE id = ANY(%s) FOR UPDATE", (ids,)).fetchall()
        by_id = {r["id"]: r for r in rows}
        detail, total = [], Decimal("0")
        for item in order.items:
            product = by_id.get(item.product_id)
            if not product or product["stock"] < item.cantidad:
                raise HTTPException(400, f"Producto {item.product_id} inexistente o sin stock")
            subtotal = product["precio"] * item.cantidad
            total += subtotal
            detail.append({"product_id": item.product_id, "nombre": product["nombre"], "cantidad": item.cantidad, "precio": str(product["precio"]), "subtotal": str(subtotal)})
            conn.execute("UPDATE products SET stock=stock-%s WHERE id=%s", (item.cantidad, item.product_id))
        return conn.execute(
            "INSERT INTO orders(customer_id,items,total) VALUES (%s,%s,%s) RETURNING *",
            (order.customer_id, json.dumps(detail), total),
        ).fetchone()
