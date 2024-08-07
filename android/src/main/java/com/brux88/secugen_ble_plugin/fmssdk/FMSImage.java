package android.src.main.java.com.brux88.secugen_ble_plugin.fmssdk;

import android.graphics.Bitmap;

import java.nio.ByteBuffer;

/**
 * Created by sbyu on 2018-12-11.
 */

public class FMSImage {

    // OPP04
    public static final int IMG_WIDTH = 258;
    public static final int IMG_HEIGHT = 336;
    public static final int IMG_SIZE = (IMG_WIDTH*IMG_HEIGHT);

    // OPP03
    public static final int IMG_WIDTH2 = 260;
    public static final int IMG_HEIGHT2 = 300;
    public static final int IMG_SIZE2 = (IMG_WIDTH2*IMG_HEIGHT2);

    // UN20
    public static final int IMG_WIDTH_UN20 =	 300;
    public static final int IMG_HEIGHT_UN20 = 400;
    public static final int IMG_SIZE_UN20 = (IMG_WIDTH_UN20*IMG_HEIGHT_UN20);

    // U10
    public static final int IMG_WIDTH_U10 = 252;
    public static final int IMG_HEIGHT_U10 = 330;
    public static final int IMG_SIZE_U10 = (IMG_WIDTH_U10*IMG_HEIGHT_U10);

    public static final int IMG_WIDTH_MAX = IMG_WIDTH_UN20;
    public static final int IMG_HEIGHT_MAX = IMG_HEIGHT_UN20;
    public static final int IMG_SIZE_MAX = (IMG_WIDTH_MAX * IMG_HEIGHT_MAX);

    private byte[] mPixels;
    private int buf_length;
    private int mWidth;
    private int mHeight;

    public FMSImage()
    {
        buf_length = 0;
    }
    public FMSImage(byte[] bytes, int length)
    {
        buf_length = length;
        if (buf_length == IMG_SIZE_U10 || buf_length == IMG_SIZE_U10/4) {
            if(buf_length == IMG_SIZE_U10)	{
                mWidth = IMG_WIDTH_U10;
                mHeight = IMG_HEIGHT_U10;
            } else	{
                mWidth = IMG_WIDTH_U10/2;
                mHeight = IMG_HEIGHT_U10/2;
            }
        } else if (buf_length == IMG_SIZE_UN20 || buf_length == IMG_SIZE_UN20/4) {
            if(buf_length == IMG_SIZE_UN20)	{
                mWidth = IMG_WIDTH_UN20;
                mHeight = IMG_HEIGHT_UN20;
            } else	{
                mWidth = IMG_WIDTH_UN20/2;
                mHeight = IMG_HEIGHT_UN20/2;
            }
        } else if(buf_length==IMG_SIZE2 || buf_length==IMG_SIZE2/4)	{
            if(buf_length==IMG_SIZE2)	{
                mWidth = IMG_WIDTH2;
                mHeight = IMG_HEIGHT2;
            } else {
                mWidth = IMG_WIDTH2/2;
                mHeight = IMG_HEIGHT2/2;
            }
        } else 	{
            if(buf_length == IMG_SIZE) {
                mWidth = IMG_WIDTH;
                mHeight = IMG_HEIGHT;
            } else	{
                mWidth = IMG_WIDTH/2;
                mHeight = IMG_HEIGHT/2;
            }
        }

        set(bytes, mWidth, mHeight);
    }

    public void set(byte[] bytes, int width, int height)
    {
        mPixels = new byte[width*height*4];
        for (int i = 0; i < buf_length; i++)
        {
            mPixels[i*4] = mPixels[i*4+1] = mPixels[i*4+2] = bytes[i];
            mPixels[i*4+3] = (byte) 0xFF;
        }
    }

    public int getmWidth()
    {
        return mWidth;
    }

    public int getmHeight()
    {
        return mHeight;
    }

    public Bitmap get()
    {
        Bitmap bmp = Bitmap.createBitmap(mWidth, mHeight, Bitmap.Config.ARGB_8888);
        bmp.copyPixelsFromBuffer(ByteBuffer.wrap(mPixels));

        return bmp;
    }
}
