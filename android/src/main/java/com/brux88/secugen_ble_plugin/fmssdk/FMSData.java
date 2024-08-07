package android.src.main.java.com.brux88.secugen_ble_plugin.fmssdk;
import static android.src.main.java.com.brux88.secugen_ble_plugin.fmssdk.FMSAPI.CMD_FP_CAPTURE;

/**
 * Created by sbyu on 2018-11-19.
 */

public class FMSData {
    public byte[] d_data;
    public int d_length;

    public void setD_length(int length) {this.d_length = length;}
    public int getD_length(int length) {return d_length;}

    public FMSData()
    {
        d_length = 0;
    }
    public FMSData(byte[] bytes)
    {
        FMSHeader header = new FMSHeader(bytes);
        if (header.pkt_command == CMD_FP_CAPTURE)
            set(bytes, ((header.pkt_datasize2 << 16) | header.pkt_datasize1));
        else
            set(bytes, header.pkt_datasize1);
    }

    public void set(byte[] bytes, int length)
    {
        d_length = length;
        d_data = new byte[length];
        System.arraycopy(bytes, 12, d_data, 0, length);
    }

    public byte[] get()
    {
        return d_data;
    }
}
