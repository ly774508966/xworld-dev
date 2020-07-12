
using UnityEngine;
using System.Collections;
using UnityEditor;
using System;
using System.IO;
using System.Collections.Generic;
using System.Xml;
using System.Text;
using marijnz.EditorCoroutines;

namespace XWorld
{
    public class OutputLinker : EditorWindow
    {
        public string xid = "";
        public string path = "D:/XWorldNode/xworld/";
        public string workpath = "D:/XWorld/";
        public string node_path;
        public string client_path;
        public string account, password;
        public bool b_pc = true;
        public bool b_android = true;
        public bool b_ios = false;

        static List<string> paths = new List<string>();
        static List<string> files = new List<string>();
        static List<AssetBundleBuild> maps = new List<AssetBundleBuild>();

        void OnGUI()
        {
            //GUILayout.Space(20);
            //GUILayout.BeginHorizontal();
            //GUILayout.Label("导出节点路径：");
            //path = EditorGUILayout.TextField(path);
            //if (!path.EndsWith("/") && !path.EndsWith("\\"))
            //{
            //    path = path + "\\";
            //}
            //GUILayout.EndHorizontal();

            //GUILayout.Space(10);
            //GUILayout.BeginHorizontal();
            //GUILayout.Label("客户端路径：");
            //client_path = EditorGUILayout.TextField(client_path);
            //GUILayout.EndHorizontal();

            GUILayout.Space(20);
            GUILayout.BeginHorizontal();
            GUILayout.Label("工作路径：");
            workpath = EditorGUILayout.TextField(workpath);
            GUILayout.EndHorizontal();

            GUILayout.Space(20);

            GUILayout.BeginHorizontal();
            GUILayout.Label("账号：");
            account = EditorGUILayout.TextField(account);
            GUILayout.EndHorizontal();
            GUILayout.Space(10);
            GUILayout.BeginHorizontal();
            GUILayout.Label("密码：");
            password = EditorGUILayout.PasswordField(password);//TextField(password);
            GUILayout.EndHorizontal();
            GUILayout.Space(10);
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("注册账号") == true)
            {
                this.StartCoroutine(ToGetXID(0));
                return;
            }
            if (GUILayout.Button("重新获得xid") == true)
            {
                this.StartCoroutine(ToGetXID(1));
                return;
            }
            GUILayout.EndHorizontal();
            GUILayout.Space(20);

            GUILayout.BeginHorizontal();
            GUILayout.Label("Linker节点XID号：");
            xid = EditorGUILayout.TextField(xid);
            GUILayout.EndHorizontal();

            GUILayout.Space(20);


            GUILayout.BeginHorizontal();
            if (GUILayout.Button("输出全部资源") == true)
            {
                //SelectBuildName.FastBuild();
                ////打包
                //isBuildABFast = true;
                ToBuild();
                return;
            }
            GUILayout.EndHorizontal();

            GUILayout.Space(5);
            GUILayout.BeginHorizontal();
            b_pc = GUILayout.Toggle(b_pc, "pc");
            b_android = GUILayout.Toggle(b_android, "android");
            b_ios = GUILayout.Toggle(b_ios, "ios");
            GUILayout.EndHorizontal();

            GUILayout.Space(10);
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("输出Lua") == true)
            {
                ToBuildLua();
                return;
            }
            GUILayout.EndHorizontal();

            GUILayout.Space(30);


            GUILayout.BeginHorizontal();
            if (GUILayout.Button("测试运行") == true)
            {
                ToRun();
                return;
            }
            GUILayout.EndHorizontal();

            GUILayout.Space(20);
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("服务节点代理") == true)
            {
                ToProxy();
                return;
            }
            GUILayout.EndHorizontal();

            //GUILayout.BeginHorizontal();
            //isProfiler = GUILayout.Toggle(isProfiler, "profiler");
            //GUILayout.EndHorizontal();

        }

        static string AppDataPath
        {
            get { return Application.dataPath.ToLower(); }
        }
        public static string md5file(string file, ref long filesize)
        {
            try
            {
                System.IO.FileInfo f = new FileInfo(file);
                filesize = f.Length;
                FileStream fs = new FileStream(file, FileMode.Open);
                System.Security.Cryptography.MD5 md5 = new System.Security.Cryptography.MD5CryptoServiceProvider();
                byte[] retVal = md5.ComputeHash(fs);
                fs.Close();
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < retVal.Length; i++)
                {
                    sb.Append(retVal[i].ToString("x2"));
                }
                return sb.ToString();
            }
            catch (Exception ex)
            {
                throw new Exception("md5file() fail, error:" + ex.Message);
            }
        }
        public static void CopyLuaBytesFiles(string sourceDir, string destDir, bool appendext = true, string searchPattern = "*.lua", SearchOption option = SearchOption.AllDirectories)
        {
            if (!Directory.Exists(sourceDir))
            {
                return;
            }

            string[] files = Directory.GetFiles(sourceDir, searchPattern, option);
            int len = sourceDir.Length;

            if (sourceDir[len - 1] == '/' || sourceDir[len - 1] == '\\')
            {
                --len;
            }

            for (int i = 0; i < files.Length; i++)
            {
                string str = files[i].Remove(0, len);
                string dest = destDir + "/" + str;
                if (appendext) dest += ".bytes";
                string dir = Path.GetDirectoryName(dest);
                Directory.CreateDirectory(dir);
                File.Copy(files[i], dest, true);
            }
        }

        void MakePath()
        {
            if (workpath[workpath.Length - 1] != '\\' && workpath[workpath.Length - 1] != '/')
            {
                workpath += "/";
            }

            client_path = workpath + "XLinker/";
            path = workpath + "XWorldNode/xworld/";
        }
        void Logon(int logontype)
        {
            MakePath();
            int index = path.LastIndexOf("\\xworld");
            node_path = path.Substring(0, index);//去掉\xworld
            string run_args = "xwbase.lua" + " account=" + account + " password=" + password + " logonmode=" + logontype + " type=1";
            //xwbase.lua account=udx100 password=098765 logonmode=1 type=1
            System.Diagnostics.ProcessStartInfo info = new System.Diagnostics.ProcessStartInfo();
            info.FileName = node_path + "/ConsoleLinkerNode.exe";
            info.Arguments = run_args;//登录或直接注册，等待返回
            info.WorkingDirectory = node_path;
            int i;

            Debug.Log(info.FileName);
            Debug.Log(run_args);
            System.Diagnostics.Process pro;
            try
            {
                pro = System.Diagnostics.Process.Start(info);
            }
            catch (System.ComponentModel.Win32Exception ex)
            {
                Debug.Log("系统找不到指定的文件。");
                Console.WriteLine("系统找不到指定的文件。/r{0}", ex.ToString());
            }
        }


        IEnumerator ToGetXID(int logontype)
        {
            MakePath();
            //linkernode登录（或注册）并得到xid，新开窗口会显示新xid和存到剪贴板中，并准备关闭
            if (account.Length < 6 || password.Length < 6)
            {
                Debug.Log("账号密码长度需要大于6!");
            }
            else
            {
                GUIUtility.systemCopyBuffer = "";
                //打开
                Logon(logontype);
                int i;
                for (i = 0; i < 10; ++i)
                {
                    string str = GUIUtility.systemCopyBuffer;
                    if (str.Length == 32)
                    {
                        xid = str;
                        break;
                    }
                    yield return new WaitForSeconds(1f);
                }
                if (i >= 10)
                {
                    Debug.Log("获取xid超时");
                }
                else
                {
                    Debug.Log("获取xid成功");
                }
            }
        }


        void RunXWorld(string run_args)
        { 
            MakePath();
            int index = path.LastIndexOf("/xworld");
            node_path = path.Substring(0, index);
            if (account.Length< 6 || password.Length< 6)
            {
                Debug.Log("账号密码长度需要大于6!");
                return;
            }
            
            //内网快速测试运行，不使用upnp
            //run_args = "xwbase.lua " + "account=" + account + " password=" + password + " linker_ip=127.0.0.1" + " delayrun=" + clientname + " type=2";//type 服务节点
            Debug.Log(run_args);
            System.Diagnostics.ProcessStartInfo info = new System.Diagnostics.ProcessStartInfo();
            info.FileName = node_path + "/ConsoleLinkerNode.exe"; 
            info.Arguments = run_args;
            info.WorkingDirectory = node_path;
            System.Diagnostics.Process pro;
            try
            {
                pro = System.Diagnostics.Process.Start(info);
            }
            catch (System.ComponentModel.Win32Exception ex)
            {
                Console.WriteLine("系统找不到指定的文件。/r{0}", ex.ToString());
                return;
            }
        }
        void ToRun()
        {
            //MakePath();
            //string run_args;
            //int index = path.LastIndexOf("/xworld");    
            //node_path = path.Substring(0, index);// path.Replace('\\', '/').Replace("xworld/", "");
            ////run_commandline = node_path + "/ConsoleLinkerNode.exe ";
            //if (account.Length < 6 || password.Length < 6)
            //{
            //    Debug.Log("账号密码长度需要大于6!");
            //    return;
            //}
            MakePath();
            string clientname;
            if (client_path.IndexOf("XWorld.exe") < 0)
            {
                clientname = client_path + "XWorld.exe";
            }
            else
            {
                clientname = client_path;
            }
            ////内网快速测试运行，不使用upnp
            //run_args = "xwbase.lua " + "account=" + account + " password=" + password + " linker_ip=127.0.0.1" + " delayrun=" + clientname + " type=2";//type 服务节点
            //Debug.Log(run_args);
            //System.Diagnostics.ProcessStartInfo info = new System.Diagnostics.ProcessStartInfo();
            //info.FileName = node_path + "/ConsoleLinkerNode.exe"; 
            //info.Arguments = run_args;
            //info.WorkingDirectory = node_path;
            //System.Diagnostics.Process pro;
            //try
            //{
            //    pro = System.Diagnostics.Process.Start(info);
            //}
            //catch (System.ComponentModel.Win32Exception ex)
            //{
            //    Console.WriteLine("系统找不到指定的文件。/r{0}", ex.ToString());
            //    return;
            //}
            string run_args = "xwbase.lua" + " account=" + account + " password=" + password + " linker_ip=127.0.0.1" + " delayrun=" + clientname + " type=2";
            RunXWorld(run_args);
        }

        void ToProxy()
        {
            //5e561dc7068a73ab000000017f000001
            string run_args = "xwreqproxy.lua" + " account=" + account + " password=" + password + " proxy=5e561dc7068a73ab000000017f000001";//此xid是放在服务器上可供代理使用的linker节点
            RunXWorld(run_args);
        }

        void ToBuildLua()
        {
            MakePath();
            //pc
            //导出 scene目录，res目录 lua/server目录， lua/Client目录
            
            string LuaPath;
            string OutputPath = path + xid + "/pc";;
            if (b_pc)
            {
                LuaPath = path + xid + "/pc/Lua";
                BuildAssetResource(BuildTarget.StandaloneWindows, OutputPath, LuaPath, true, false, false);
            }
            if (b_android)
            {
                LuaPath = path + xid + "/android/Lua";
                OutputPath = path + xid + "/android";
                BuildAssetResource(BuildTarget.Android, OutputPath, LuaPath, true, false, false);
            }
            if (b_ios)
            {
                LuaPath = path + xid + "/ios/Lua";
                OutputPath = path + xid + "/ios";
                BuildAssetResource(BuildTarget.iOS, OutputPath, LuaPath, true, false, false);
            }
            //生成ver.txt
            string VerPath = path + xid + "/ver.txt";
            long filesize = 0;
            string md5 = md5file(OutputPath + "/filelist.txt", ref filesize);
            FileStream fs = new FileStream(VerPath, FileMode.Create);
            StreamWriter sw = new StreamWriter(fs);
            //写入md5
            //sw.WriteLine("[Init]");
            //sw.WriteLine("MD5=" + md5);
            sw.WriteLine(md5);
            sw.Close(); fs.Close();

            // 复制lua / server 生成文件列表与版本号
            string luaServerDir = Application.dataPath + "/Lua/server";
            string destServerDir = path + xid + "/server";
            CopyAllFiles(luaServerDir, path + xid + "/server");
            //生成server/filelist.txt ver.txt
            BuildFileIndex(destServerDir);
            VerPath = destServerDir + "/ver.txt";
            md5 = md5file(destServerDir + "/filelist.txt", ref filesize);
            fs = new FileStream(VerPath, FileMode.Create);
            sw = new StreamWriter(fs);
            sw.WriteLine(md5);
            sw.Close(); fs.Close();
        }

        void ToBuild()
        {
            MakePath();
            if (xid.Length != 32)
            {
                Debug.Log("请使用正确的XID字符串！（XWorld客户端注册后自动保存到剪贴板的）");
            }
            //pc
            //导出 scene目录，res目录 lua/server目录， lua/Client目录
            string OutputPath = path + xid + "/pc";
            if (b_pc)
            {
                BuildAssetResource(BuildTarget.StandaloneWindows, OutputPath);
            }
            if (b_android)
            {
                OutputPath = path + xid + "/android";
                BuildAssetResource(BuildTarget.Android, OutputPath);
            }

            if (b_ios)
            {
                OutputPath = path + xid + "/ios";
                BuildAssetResource(BuildTarget.iOS, OutputPath);
            }
            //android and ios
            //OutputPath = path + xid + "/android/";
            //BuildAssetResource(BuildTarget.Android, OutputPath);
            //Debug.Log("Finish Android Resource Output");
            //OutputPath = path + xid + "/iod/";
            //BuildAssetResource(BuildTarget.iOS, OutputPath);
            //Debug.Log("Finish iOS Resource Output");

            //生成ver.txt
            string VerPath = path + xid + "/ver.txt" ;
            long filesize = 0;
            string md5 = md5file(OutputPath + "/filelist.txt", ref filesize);
            FileStream fs = new FileStream(VerPath, FileMode.Create);
            StreamWriter sw = new StreamWriter(fs);
            //写入md5
            //sw.WriteLine("[Init]");
            //sw.WriteLine("MD5=" + md5);            
            sw.WriteLine(md5);
            sw.Close(); fs.Close();

            //复制lua/server
            string luaServerDir = Application.dataPath + "/Lua/server";
            string destServerDir = path + xid + "/server";
            CopyAllFiles(luaServerDir, path + xid + "/server");
            //生成server/filelist.txt ver.txt
            BuildFileIndex(destServerDir);
            VerPath = destServerDir + "/ver.txt";
            md5 = md5file(destServerDir + "/filelist.txt", ref filesize);
            fs = new FileStream(VerPath, FileMode.Create);
            sw = new StreamWriter(fs);
            sw.WriteLine(md5);
            sw.Close(); fs.Close();

            Debug.Log("Finish Resource Output");
        }

        public static void BuildAssetResource(BuildTarget target, string OutputPath, string deletePath = "", bool bLua = true, bool bScene = true, bool bRes = true )
        {
            if (deletePath == "")
                deletePath = OutputPath;
            if (Directory.Exists(deletePath))
            {
                Directory.Delete(deletePath, true);
            }
            Directory.CreateDirectory(deletePath);
            AssetDatabase.Refresh();

            maps.Clear();
            //lua
            if (bLua)
            {
                Debug.Log("Output Lua");
                if (AppConst.LuaBundleMode)
                {
                    HandleLuaBundle();
                }
                else
                {
                    HandleLuaFile();
                }
            }
            //scene
            if (bScene)
            {
                Debug.Log("Output Scene");
                HandleScene();
            }
            //res
            if (bRes)
            {
                Debug.Log("Output Res");
                HandleResouce();
            }
            //string resPath = "Assets/" + AppConst.AssetDir;
            BuildPipeline.BuildAssetBundles(OutputPath, maps.ToArray(), BuildAssetBundleOptions.None, target);//OutputPath
            
            BuildFileIndex(OutputPath);

            //sheng

            string streamDir = Application.dataPath + "/" + AppConst.LuaTempDir;
            if (Directory.Exists(streamDir)) Directory.Delete(streamDir, true);
            AssetDatabase.Refresh();
        }

        static void CopyAllFiles(string sSrcPath, string sDestPath)
        {
            paths.Clear(); files.Clear();
            string luaDataPath = sSrcPath.ToLower();
            Recursive(luaDataPath);

            int n = 0;
            foreach (string f in files)
            {
                if (f.EndsWith(".meta")) continue;
                string newfile = f.Replace(luaDataPath, "");
                string newpath = sDestPath + newfile;
                string path = Path.GetDirectoryName(newpath);
                if (!Directory.Exists(path)) Directory.CreateDirectory(path);

                if (File.Exists(newpath))
                {
                    File.Delete(newpath);
                }
                File.Copy(f, newpath, true);
                UpdateProgress(n++, files.Count, newpath);
            }

            EditorUtility.ClearProgressBar();
            AssetDatabase.Refresh();
        }
        static void HandleLuaBundle()
        {
            string streamDir = Application.dataPath + "/" + AppConst.LuaTempDir;
            if (!Directory.Exists(streamDir)) Directory.CreateDirectory(streamDir);

            string luaDir = Application.dataPath + "/Lua/client/";
            string[] srcDirs = { luaDir };
            int i, j;
            for ( i = 0; i < srcDirs.Length; i++)
            {
                
                string[] files = Directory.GetFiles(srcDirs[i], "*.lua", SearchOption.AllDirectories);
                int len = srcDirs[i].Length;

                for ( j = 0; j < files.Length; j++)
                {
                    string str = files[j].Remove(0, len);//相对路径
                    string name = str + ".bytes"; ;
                    name = name.Replace('\\', '_').Replace('/', '_');
                    string dest = streamDir + name;

                    File.Copy(files[j], dest, true);
                }
            }
            //全部文件打到一个包里client.xwp
            AddBuildMap("lua/client" + AppConst.ExtName, "*.bytes", "Assets/" + AppConst.LuaTempDir);//必须以Assets开始

            AssetDatabase.Refresh();
            
        }

        /// <summary>
        /// 把lua 客户端导出
        /// </summary>
        static void HandleLuaFile()
        {
            //string resPath = AppDataPath + "/StreamingAssets/";
            //string luaPath = resPath + "/lua/";

            ////----------复制Lua文件----------------
            //if (!Directory.Exists(luaPath))
            //{
            //    Directory.CreateDirectory(luaPath);
            //}
            //string[] luaPaths = { AppDataPath + "/FrameSyncUnity/lua/",
            //                  AppDataPath + "/FrameSyncUnity/Tolua/Lua/" };

            //for (int i = 0; i < luaPaths.Length; i++)
            //{
            //    paths.Clear(); files.Clear();
            //    string luaDataPath = luaPaths[i].ToLower();
            //    Recursive(luaDataPath);
            //    int n = 0;
            //    foreach (string f in files)
            //    {
            //        if (f.EndsWith(".meta")) continue;
            //        string newfile = f.Replace(luaDataPath, "");
            //        string newpath = luaPath + newfile;
            //        string path = Path.GetDirectoryName(newpath);
            //        if (!Directory.Exists(path)) Directory.CreateDirectory(path);

            //        if (File.Exists(newpath))
            //        {
            //            File.Delete(newpath);
            //        }
            //        //if (AppConst.LuaByteMode)
            //        //{
            //        //    EncodeLuaFile(f, newpath);
            //        //}
            //        //else
            //        File.Copy(f, newpath, true);
            //        UpdateProgress(n++, files.Count, newpath);
            //    }
            //}
            //EditorUtility.ClearProgressBar();
            //AssetDatabase.Refresh();
        }
        static void HandleScene()
        {
            string resDir = Application.dataPath + "/Scene";
            string[] dirs = Directory.GetFiles(resDir);

            for (int i = 0; i < dirs.Length; i++)
            {
                if (dirs[i].EndsWith(".unity"))
                {
                    string filename = dirs[i].Replace(resDir, string.Empty);
                    
                    //AddBuildMap(name, "*.unity", resDir);
                    string[] scene = { "Assets/Scene"+ filename };//路径必须以Assets开始

                    if (filename[0] == '/' || filename[0] == '\\')
                    {
                        filename = filename.Substring(1, filename.Length - 1);
                    }
                    string name = filename.Replace('\\', '_').Replace('/', '_');
                    name = name.Replace(".unity", ".xwp").ToLower();
                    AssetBundleBuild build = new AssetBundleBuild();
                    build.assetBundleName = name;
                    build.assetNames = scene;
                    maps.Add(build);
                }
            }
            AssetDatabase.Refresh();
        }
        static void HandleResouce()
        {
            string resDir = Application.dataPath + "/Res";
            string[] dirs = Directory.GetDirectories(resDir, "*", SearchOption.AllDirectories);
            for (int i = 0; i < dirs.Length; i++)
            {
                string path = dirs[i];
                string pathname = dirs[i].Replace(resDir, string.Empty);
                string name = pathname.Replace('\\', '_').Replace('/', '_');
                name = "res" + name.ToLower() + AppConst.ExtName;

                AddBuildMap(name, "*.*", "Assets/Res" + pathname);//路径必须以Assets开始  *.*name + AppConst.ExtName, "*.*", dirPath)
            }
            AddBuildMap("res/res" + AppConst.ExtName, "*.*", "Assets/Res/");
            AssetDatabase.Refresh();
        }

        static void BuildFileIndex(string resPath)
        {
            //string resPath = AppDataPath + "/StreamingAssets/";
            ///----------------------创建文件列表-----------------------
            string newFilePath = resPath + "/filelist.txt";
            if (File.Exists(newFilePath)) File.Delete(newFilePath);

            paths.Clear(); files.Clear();
            Recursive(resPath);

            FileStream fs = new FileStream(newFilePath, FileMode.Create);
            StreamWriter sw = new StreamWriter(fs);
            long filesize = 0;
            resPath = resPath.Replace('\\', '/');
            resPath += "/";
            for (int i = 0; i < files.Count; i++)
            {
                string file = files[i];
                string ext = Path.GetExtension(file);
                if (file.EndsWith(".meta") || file.Contains(".DS_Store")) continue;

                string md5 = md5file(file, ref filesize);
                string smd5 = md5.Substring(0, 32);
                string value = file.Replace(resPath, string.Empty);
                sw.WriteLine(value + "," + smd5 + "," + filesize);
            }
            sw.Close(); fs.Close();
        }

        /// <summary>
        /// 遍历目录及其子目录
        /// </summary>
        static void Recursive(string path)
        {
            string[] names = Directory.GetFiles(path);
            string[] dirs = Directory.GetDirectories(path);
            foreach (string filename in names)
            {
                string ext = Path.GetExtension(filename);
                if (ext.Equals(".meta")) continue;
                files.Add(filename.Replace('\\', '/'));
            }
            foreach (string dir in dirs)
            {
                paths.Add(dir.Replace('\\', '/'));
                Recursive(dir);
            }
        }
        static void AddBuildMap(string bundleName, string pattern, string path)
        {
            string[] files = Directory.GetFiles(path, pattern);
            if (files.Length == 0) return;

            for (int i = 0; i < files.Length; i++)
            {
                files[i] = files[i].Replace('\\', '/');
            }
            AssetBundleBuild build = new AssetBundleBuild();
            build.assetBundleName = bundleName;
            build.assetNames = files;
            maps.Add(build);
        }

        static void UpdateProgress(int progress, int progressMax, string desc)
        {
            string title = "Processing...[" + progress + " - " + progressMax + "]";
            float value = (float)progress / (float)progressMax;
            EditorUtility.DisplayProgressBar(title, desc, value);
        }
    }
}