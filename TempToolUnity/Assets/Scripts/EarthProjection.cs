using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EarthProjection : MonoBehaviour
{
    private Texture2DArray texturArray;
    public Gradient gradient;
    public APIComm apiComm;

    public void LoadVariableData(APIComm.VariableData data)
    {
        texturArray = new Texture2DArray(data.LongitudeRes, data.LatitudeRes, data.TimeRes, TextureFormat.RGBA32, false, false);
        for (int t = 0; t < data.TimeRes; t++)
        {
            Color32[] colors = new Color32[data.LatitudeRes * data.LongitudeRes];
            for (int lat = 0; lat < data.LatitudeRes; lat++)
            {
                for (int lon = 0; lon < data.LongitudeRes; lon++)
                {
                    colors[lat * data.LongitudeRes + lon] = gradient.Evaluate(data.ValueNorm(t, 0, lat, lon));
                }
            }
            texturArray.SetPixels32(colors, t, 0);
        }
        texturArray.Apply(false);
        var material = GetComponent<Renderer>().material;
        material.SetTexture("Texture2DArray_2FDB4295", texturArray);
    }

    // Start is called before the first frame update
    void Start()
    {
        APIComm.VariableData data = apiComm.GetVariableData("", "");
        LoadVariableData(data);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
