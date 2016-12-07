using System;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace PrintVersion
{
  class Program
  {
    static void Main(string[] args)
    {
      string version = IsRevisionOnly(args) ? GetRevision(args) : GetVersionStem() + "." + GetRevision(args);
      Console.Write("{0}", version);
    }

    static bool IsRevisionOnly(string[] args)
    {
      bool isRevisionOnly = false;

      foreach (string arg in args)
      {
        if (arg.Equals("-RevisionOnly", StringComparison.InvariantCultureIgnoreCase) ||
            arg.Equals("/RevisionOnly", StringComparison.InvariantCultureIgnoreCase))
        {
          isRevisionOnly = true;
          break;
        }
      }

      return isRevisionOnly;
    }

    static bool IsUserSuppliedRevision(string[] args)
    {
      bool isUserSuppliedRevision = false;

      foreach (string arg in args)
      {
        if (arg.Equals("-Revision", StringComparison.InvariantCultureIgnoreCase) ||
            arg.Equals("/Revision", StringComparison.InvariantCultureIgnoreCase))
        {
          isUserSuppliedRevision = true;
          break;
        }
      }

      return isUserSuppliedRevision;
    }

    static string GetUserSuppliedRevision(string[] args)
    {
      string userSuppliedRevision = "";

      int ix = 0;
      foreach (string arg in args)
      {
        if (arg.Equals("-Revision", StringComparison.InvariantCultureIgnoreCase) ||
            arg.Equals("/Revision", StringComparison.InvariantCultureIgnoreCase))
        {
          userSuppliedRevision = args[ix + 1];
          break;
        }

        ix++;
      }

      return userSuppliedRevision;
    }

    static string GetVersionStem()
    {
      string versionStem = "";

      // string file = @"D:\SVN_Work\BGC\2014crc9\PlatformVersion\VersionStem.txt";
      string file = @"..\..\..\..\..\version.txt";

      try
      {
        versionStem = File.ReadLines(file).FirstOrDefault();
      }
      catch (Exception e)
      {
        Console.WriteLine(e);
      }

      return versionStem;
    }

    static string GetRevisionFromSVNWorkingFolder()
    {
      string revision = "";

      try
      {
        Process p = new Process();
        p.StartInfo.UseShellExecute = false;
        p.StartInfo.RedirectStandardOutput = true;
        // p.StartInfo.WorkingDirectory = @"D:\SVN_Work\BGC\2014crc9";
        p.StartInfo.WorkingDirectory = @"..";
        p.StartInfo.FileName = "svn.exe";
        p.StartInfo.Arguments = "info";
        p.Start();
        string output = p.StandardOutput.ReadToEnd();
        p.WaitForExit();

        string[] lines = output.Split("\r\n".ToCharArray(), StringSplitOptions.RemoveEmptyEntries);
        foreach (string line in lines)
        {
          if (line.StartsWith("Revision: "))
          {
            revision = line.Replace("Revision: ", "");
            break;
          }
        }
      }
      catch (Exception e)
      {
        Console.WriteLine(e);
      }

      return revision;
    }

    static string GetRevision(string[] args)
    {
      if (IsUserSuppliedRevision(args))
      {
        return GetUserSuppliedRevision(args);
      }
      else
      {
        return GetRevisionFromSVNWorkingFolder();
      }
    }
  }
}
