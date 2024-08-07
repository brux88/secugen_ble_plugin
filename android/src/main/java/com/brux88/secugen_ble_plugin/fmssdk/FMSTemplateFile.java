package android.src.main.java.com.brux88.secugen_ble_plugin.fmssdk;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.Environment;
import androidx.annotation.NonNull;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

public class FMSTemplateFile {
    private String path = "sgData";
    private String fileName = "Template.dat";
    private String fileNameTwoTemplates = "TwoTemplates.dat";
    private int imgSize = 0;

    public FMSTemplateFile() {

    }

    public void write(byte[] templateBuf, int nSize, int nNumTemplates) {
        FileOutputStream fileOutputStream = null;
        try {
            if (nNumTemplates == 1 || nNumTemplates == 2) {
                // delete the contents of a file without deleting the file itself.
                new FileOutputStream(getFilePath(nNumTemplates)).close();

                fileOutputStream = new FileOutputStream(getFilePath(nNumTemplates));
                fileOutputStream.write(templateBuf, 0, nSize);
            } else {
                return; // The error in this sample
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (fileOutputStream != null) {
                    fileOutputStream.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    public byte[] read(int nNumTemplates) {
        FileInputStream inputStream = null;
        try {
            if (nNumTemplates == 1 || nNumTemplates == 2) {
                inputStream = new FileInputStream(getFilePath(nNumTemplates));
                int templateSize = inputStream.available();

                byte[] templateBuf = new byte[templateSize];
                inputStream.read(templateBuf);

                return templateBuf;
            } else {
                return null; // The error in this sample
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (inputStream != null) {
                    inputStream.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return null;
    }

    @NonNull
    @org.jetbrains.annotations.Contract(" -> new")
    private File getFilePath(int nNumTemplates) {
        File directory = null;
        directory = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), path);

        if (!directory.exists()) {
            if (!directory.mkdirs()) {
                Log.d("FMSTemplateFile", "Failed to create directory");
                return null;
            }
        }

        if (nNumTemplates == 1)
            return new File(directory, fileName);
        else
            return new File(directory, fileNameTwoTemplates);
    }
}
