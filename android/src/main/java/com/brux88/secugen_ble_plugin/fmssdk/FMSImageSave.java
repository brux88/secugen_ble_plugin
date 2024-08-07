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

public class FMSImageSave {
    private String path = "sgkImage";
    private String fileName = "image.raw";
    private int imgSize = 0;

    public FMSImageSave() {

    }

    public void Do(byte[] rawBuf, int nSize) {
        FileOutputStream fileOutputStream = null;
        try {
            fileOutputStream = new FileOutputStream(getFilePath());
            fileOutputStream.write(rawBuf, 0, nSize);
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

    public Bitmap Do() {
        FileInputStream inputStream = null;
        try {
            inputStream = new FileInputStream(getFilePath());
            byte[] imgBuf = new byte[inputStream.available()];
            inputStream.read(imgBuf);

            FMSImage Img = new FMSImage(imgBuf, inputStream.available());
            return Img.get();
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

    public byte[] getImgBuf() {
        FileInputStream inputStream = null;
        try {
            inputStream = new FileInputStream(getFilePath());
            imgSize = inputStream.available();

            byte[] imgBuf = new byte[imgSize];
            inputStream.read(imgBuf);

            return imgBuf;
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
    private File getFilePath() {
        File directory = null;
        directory = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), path);

        if (!directory.exists()) {
            if (!directory.mkdirs()) {
                Log.d("FMSImageSave", "Failed to create directory");
                return null;
            }
        }

        return new File(directory, fileName);
    }

    public int getImgSize() {
        return imgSize;
    }
}
