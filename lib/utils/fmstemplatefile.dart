import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart'; // Per @nonNull

class FMSTemplateFile {
  String path = "sgData";
  String fileName = "Template.dat";
  String fileNameTwoTemplates = "TwoTemplates.dat";
  int imgSize = 0;

  FMSTemplateFile();

  Future<void> write(
      Uint8List templateBuf, int nSize, int nNumTemplates) async {
    File file;
    try {
      if (nNumTemplates == 1 || nNumTemplates == 2) {
        // Ottieni il percorso del file
        file = await _getFilePath(nNumTemplates);

        // Elimina il contenuto del file senza eliminare il file stesso
        await file.writeAsBytes(Uint8List(0), mode: FileMode.write);

        // Scrivi i dati sul file
        var fileResult = await file.writeAsBytes(templateBuf.sublist(0, nSize),
            mode: FileMode.write);
        print("Process Complete: ${fileResult.path}");
      } else {
        return; // Errore
      }
    } catch (e) {
      print('Errore durante la scrittura del file: $e');
    }
  }

  Future<Uint8List?> read(int nNumTemplates) async {
    File file;
    try {
      if (nNumTemplates == 1 || nNumTemplates == 2) {
        // Ottieni il percorso del file
        file = await _getFilePath(nNumTemplates);

        // Leggi i dati dal file
        Uint8List templateBuf = await file.readAsBytes();
        return templateBuf;
      } else {
        return null; // Errore
      }
    } catch (e) {
      print('Errore durante la lettura del file: $e');
    }
    return null;
  }

  Future<File> _getFilePath(int nNumTemplates) async {
    // Ottieni la directory dei documenti
    Directory? directory = await getExternalStorageDirectory();

    if (directory != null) {
      Directory sgDataDirectory = Directory('${directory.path}/$path');

      if (!(await sgDataDirectory.exists())) {
        await sgDataDirectory.create(recursive: true);
      }

      if (nNumTemplates == 1) {
        return File('${sgDataDirectory.path}/$fileName');
      } else {
        return File('${sgDataDirectory.path}/$fileNameTwoTemplates');
      }
    } else {
      throw Exception('Directory non trovata');
    }
  }
}
