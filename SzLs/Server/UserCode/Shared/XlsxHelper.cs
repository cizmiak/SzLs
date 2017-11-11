using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using DocumentFormat.OpenXml.Packaging;
using OpenXmlPowerTools;

namespace LightSwitchApplication
{
	public static class XlsxHelper
	{
		public static void Read(FileStream fileStream)
		{
			using (fileStream)
			{
				if (fileStream.Length > 0)
				{
					//var xlsxDoc = SpreadsheetDocument.Open(fileStream, false);
					//var sheets = SmlDataRetriever.SheetNames(xlsxDoc);

					//xlsxDoc.Close();
					fileStream.Close();
				}
			}
		}
	}
}