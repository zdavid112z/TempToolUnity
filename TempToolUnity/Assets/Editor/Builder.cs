using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class Builder : MonoBehaviour
{
    public static void BuildWebGL()
    {
        string[] scenes = { "Assets/Scenes/SampleScene.unity" };
        string pathToDeploy = "builds/WebGL/";

        Debug.Log("###   BUILD START   ###");
        var r = BuildPipeline.BuildPlayer(scenes, pathToDeploy, BuildTarget.WebGL, BuildOptions.None);
        Debug.Log("###   BUILD END   ###");
        Debug.Log(r);
    }
}
