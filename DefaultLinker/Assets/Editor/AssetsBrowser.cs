
using UnityEngine;
using System.Collections;
using UnityEditor;
using System;
using System.IO;
using System.Collections.Generic;
using System.Xml;
using System.Text;
using UnityEngine.Networking;

namespace XWorld
{
    public class AssetsBrowser : EditorWindow
    {
        public string assetsname = "";
        public string path = "";

        static List<string> paths = new List<string>();
        static List<string> files = new List<string>();
        static List<AssetBundleBuild> maps = new List<AssetBundleBuild>();

        readonly List<string> AssetsList = new List<string>();
        Vector2 scrollPosition;

        void OnGUI()
        {
            GUILayout.Space(20);
            GUILayout.BeginHorizontal();
            //if (GUILayout.Button("查看ABManifest资源") == true)
            //{
            //    UnityEngine.Object ob = Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.Assets)[0];//EditorUtil.GetSelectionList()[0];
            //    string url = Application.dataPath;
            //    url = url.Replace("Assets", "") + AssetDatabase.GetAssetPath(ob);

            //    if (url != "")
            //    {
            //        AssetBundle assetBundle = AssetBundle.LoadFromFile(url);
            //        AssetBundleManifest abm = assetBundle.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
            //        if (abm)
            //        {
            //            Debug.Log("Load xid manifest : " + url);
            //        }
            //        else 
            //        {
            //            Debug.Log("Load xid manifest Failed: " + url);
            //        }
            //        assetBundle.Unload(true);
            //    }
            //}
            if (GUILayout.Button("查看选中资源") == true)
            {
                UnityEngine.Object ob = Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.Assets)[0];//EditorUtil.GetSelectionList()[0];
                string url = Application.dataPath;
                url = url.Replace("Assets", "") + AssetDatabase.GetAssetPath(ob);

                if (url != "")
                {
                    if (File.Exists(url))
                    {
                        AssetsList.Clear();
                        UnityWebRequest uwr = UnityWebRequest.Get(url);
                        //yield return uwr.SendWebRequest();
                        uwr.SendWebRequest();
                        var bytes = uwr.downloadHandler.data;
                        
                        //var bytes = File.ReadAllBytes(url);
                        AssetBundle bundle = AssetBundle.LoadFromMemory(bytes);
                        string buffer;
                        if (bundle != null)
                        {//兼容原来的结构加上lua头
                            //TextAsset luaCode = bundle.LoadAsset<TextAsset>("ddddent.lua");
                            //if (luaCode != null)
                            //{
                            //    AssetsList.Add(System.Text.Encoding.Default.GetString(luaCode.bytes));
                            //}
                            UnityEngine.Object[] obj = bundle.LoadAllAssets();
                            for (int i = 0; i < obj.Length; i++)
                            {
                                AssetsList.Add(obj[i].name);
                            }
                            bundle.Unload(true);
                        }
                    }
                }
                return;
            }
            GUILayout.EndHorizontal();
            GUILayout.Space(20);

            GUILayout.BeginHorizontal();
            GUILayout.Label(assetsname);
            //assetsname = EditorGUILayout.TextField(assetsname);
            GUILayout.EndHorizontal();

            scrollPosition = GUILayout.BeginScrollView(scrollPosition);
            for (var i = 0; i < AssetsList.Count; i++)
            {
                GUILayout.Label(AssetsList[i]);
            }
            GUILayout.EndScrollView();


            //GUILayout.BeginHorizontal();
            //isProfiler = GUILayout.Toggle(isProfiler, "profiler");
            //GUILayout.EndHorizontal();

        }

        static string AppDataPath
        {
            get { return Application.dataPath.ToLower(); }
        }
        
    }
}