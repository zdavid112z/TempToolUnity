using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class APIComm : MonoBehaviour
{
    [System.Serializable]
    public struct VariableData {
        public float[] data;
        public int[] dimensions;
        public int latitude;
        public int longitude;
        public int time;
        public int level;

        public int[] sizes;
        public float minValue, maxValue;

        public int LatitudeRes
        {
            get { return dimensions[latitude]; }
        }

        public int LongitudeRes
        {
            get { return dimensions[longitude]; }
        }

        public int TimeRes
        {
            get { return dimensions[time]; }
        }

        public int LevelRes
        {
            get { return dimensions[level]; }
        }

        public void MakeValueAvailable() {
            sizes = new int[dimensions.Length + 1];
            sizes[dimensions.Length] = 0;
            int val = 1;
            for (int i = dimensions.Length - 1; i >= 0; i--) {
                sizes[i] = val;
                val *= dimensions[i];
            }
            latitude = latitude == -1 ? dimensions.Length : latitude;
            longitude = longitude == -1 ? dimensions.Length : longitude;
            time = time == -1 ? dimensions.Length : time;
            level = level == -1 ? dimensions.Length : level;
        }

        public void CalcMinMaxValues() {
            minValue = data[0];
            maxValue = data[0];
            for (int i = 1; i < data.Length; i++) {
                minValue = Mathf.Min(minValue, data[i]);
                maxValue = Mathf.Max(maxValue, data[i]);
            }
        }

        public ref float RawValue(int t, int l, int lat, int lon) {
            return ref data[
                t * sizes[time] + 
                l * sizes[level] + 
                lat * sizes[latitude] + 
                lon * sizes[longitude]];
        }

        public float ValueNorm(int t, int l, int lat, int lon)
        {
            return (RawValue(t, l, lat, lon) - minValue) / (maxValue - minValue);
        }
    }

    public VariableData GetVariableData(string fileName, string variableName) {
        VariableData data = new VariableData
        {
            dimensions = new int[] { 4, 256, 256 },
            latitude = 2,
            longitude = 1,
            time = 0,
            level = -1,
            data = new float[4 * 256 * 256]
        };
        data.MakeValueAvailable();

        for (int t = 0; t < data.dimensions[0]; t++) {
            for (int lo = 0; lo < data.dimensions[1]; lo++) {
                for (int la = 0; la < data.dimensions[2]; la++) {
                    data.RawValue(t, 0, la, lo) = (float)Mathf.PerlinNoise((la + t * 10) * 0.1f, (lo + t * 10) * 0.1f);
                }
            }
        }
        data.CalcMinMaxValues();
        
        return data;
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
