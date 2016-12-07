using System;
using Microsoft.Web.XmlTransform;

// http://sedodream.com/2013/02/02/HowToInvokeXDTFromCode.aspx
// http://www.gregpakes.co.uk/post/using-webconfig-transforms-in-your-own-application
// http://www.developerblogger.com/3896_9006625/

namespace ConfigFileTransform
{
  class Program
  {
    static int Main(string[] args)
    {
      try
      {
        string baseConfigFileName = args[0];
        string transformFileName = args[1];
        string outputConfigFileName = args[2];
        // Console.WriteLine("Transforming\n  base file: {0}\n  transform file: {1}\n  output file: {2}", baseConfigFileName, transformFileName, outputConfigFileName);
        TransformConfig(baseConfigFileName, transformFileName, outputConfigFileName);
      }
      catch (Exception e)
      {
        Console.WriteLine("Exception: {0}", e.Message);
        return 1;
      }

      return 0;
    }

    public static void TransformConfig(string baseConfigFileName, string transformFileName, string outputConfigFileName)
    {
      var document = new XmlTransformableDocument();
      document.PreserveWhitespace = true;
      document.Load(baseConfigFileName);

      var transformation = new XmlTransformation(transformFileName);
      if (!transformation.Apply(document))
      {
        throw new Exception("Transformation Failed");
      }
      document.Save(outputConfigFileName);
    }
  }
}
