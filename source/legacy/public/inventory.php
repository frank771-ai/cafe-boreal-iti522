<?php
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
$dbPath = '/tmp/legacy.sqlite';
$db = new PDO('sqlite:' . $dbPath);
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$db->exec('CREATE TABLE IF NOT EXISTS inventory (sku TEXT PRIMARY KEY, nombre TEXT NOT NULL, stock INTEGER NOT NULL)');
if ((int)$db->query('SELECT COUNT(*) FROM inventory')->fetchColumn() === 0) {
  $stmt = $db->prepare('INSERT INTO inventory(sku,nombre,stock) VALUES(?,?,?)');
  for ($i=1; $i<=50; $i++) $stmt->execute([sprintf('CB-%03d',$i), 'Café Boreal '.$i, 20 + ($i % 17)]);
}
$sku = $_GET['sku'] ?? null;
if ($sku) {
  $stmt = $db->prepare('SELECT sku,nombre,stock FROM inventory WHERE sku=?');
  $stmt->execute([$sku]);
  $result = $stmt->fetch(PDO::FETCH_ASSOC);
  http_response_code($result ? 200 : 404);
  echo json_encode($result ?: ['error'=>'SKU no encontrado'], JSON_UNESCAPED_UNICODE);
} else {
  echo json_encode($db->query('SELECT sku,nombre,stock FROM inventory ORDER BY sku')->fetchAll(PDO::FETCH_ASSOC), JSON_UNESCAPED_UNICODE);
}
