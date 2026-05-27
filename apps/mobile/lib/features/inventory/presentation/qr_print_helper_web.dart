import 'dart:convert';
import 'dart:js_interop';

import '../data/models/item_model.dart';

@JS('eval')
external void _jsEval(String code);

String _buildPrintHtml(List<ItemModel> items) {
  final cards = items.map((item) {
    final qrCode = item.qrCode!;
    final src =
        qrCode.startsWith('data:') ? qrCode : 'data:image/png;base64,$qrCode';
    final name = item.name
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    final location = [item.propertyName, item.roomName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' › ');
    return '<div class="card">'
        '<img src="$src" alt="QR"/>'
        '<p class="name">$name</p>'
        '${location.isNotEmpty ? '<p class="loc">$location</p>' : ''}'
        '</div>';
  }).join('');

  return '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>QR Codes — Vaulted</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;background:#fff;padding:20px}
  h2{font-size:16px;font-weight:600;color:#111;margin-bottom:16px}
  .grid{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}
  .card{border:1px solid #ddd;border-radius:8px;padding:10px;text-align:center;break-inside:avoid}
  .card img{width:120px;height:120px;display:block;margin:0 auto}
  .name{font-size:11px;font-weight:600;color:#111;margin-top:6px;word-break:break-word}
  .loc{font-size:10px;color:#757575;margin-top:2px}
  @media print{body{padding:8px}.grid{gap:8px}}
</style>
</head>
<body>
<h2>QR Codes &mdash; Vaulted &nbsp; (${items.length} item${items.length == 1 ? '' : 's'})</h2>
<div class="grid">$cards</div>
</body>
</html>''';
}

void printQrItems(List<ItemModel> items) {
  final html = _buildPrintHtml(items);
  final jsHtml = jsonEncode(html);
  _jsEval('''
(function(){
  var w=window.open('','_blank','width=960,height=700');
  if(!w){alert('Allow pop-ups for this site to print QR codes.');return;}
  w.document.write($jsHtml);
  w.document.close();
  w.focus();
  w.addEventListener('load',function(){w.print();});
})();
''');
}
