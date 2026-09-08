import 'dart:typed_data';
import 'package:esc_pos_utils_2/esc_pos_utils_2.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:image/image.dart' as img;

class PrinterService {
  final PrinterManager _printerManager = PrinterManager.instance;

  // 1. በ Network (LAN IP) ፕሪንተር ደረሰኝ ማተም (ለካሸር እና ወጥ ቤት)
  Future<void> printReceiptNetwork({
    required String ipAddress,
    required List<String> orderItems,
    required double totalPrice,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      'HOTEL SMART POS',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.feed(1);

    // Items
    for (var item in orderItems) {
      bytes += generator.text(item);
    }

    bytes += generator.hr();
    bytes += generator.text(
      'TOTAL: ETB ${totalPrice.toStringAsFixed(2)}',
      styles: const PosStyles(bold: true, align: PosAlign.right),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    // Send to Printer IP
    await _printerManager.connect(
      type: PrinterType.network,
      model: NetworkPrinterInput(ipAddress: ipAddress, port: 9100),
    );
    await _printerManager.send(type: PrinterType.network, bytes: bytes);
    await _printerManager.disconnect(type: PrinterType.network);
  }
}
// አማርኛን ወደ Bitmap Image ቀይሮ የ ESC/POS Image Bytes ማዘጋጀት
  List<int> generateAmharicImageBytes(Generator generator, img.Image amharicTextImage) {
    List<int> bytes = [];
    // ምስሉን ወደ ESC/POS Raster Image ይቀይረዋል
    bytes += generator.imageRaster(amharicTextImage);
    bytes += generator.feed(1);
    return bytes;
  }