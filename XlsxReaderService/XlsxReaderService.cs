using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.ServiceModel.DomainServices.Server;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Spreadsheet;

namespace XlsxReaderService
{
	// NOTE: You can use the "Rename" command on the "Refactor" menu to change the class name "Service1" in both code and config file together.
	public class XlsxReaderService : DomainService
	{
		#region XlsxBytes
		private static ConcurrentDictionary<Guid, XlsxBytes> XlsxBytes { get; set; } =
			new ConcurrentDictionary<Guid, XlsxBytes>();

		[Query(IsDefault = true)]
		public IQueryable<XlsxBytes> GetXlsxBytes()
		{
			return XlsxBytes.Values.AsQueryable();
		}

		[Update]
		public void UpdateXlsxBytes(XlsxBytes xlsxBytes)
		{
			XlsxBytes.AddOrUpdate(xlsxBytes.Id, xlsxBytes, (k,v) => xlsxBytes);
		}

		[Insert]
		public void InsertXlsxBytes(XlsxBytes xlsxBytes)
		{
			XlsxBytes.AddOrUpdate(xlsxBytes.Id, xlsxBytes, (k, v) => xlsxBytes);
		}

		[Delete]
		public void DeleteXlsxBytes(XlsxBytes xlsxBytes)
		{
			XlsxBytes.TryRemove(xlsxBytes.Id, out xlsxBytes);
		}
		#endregion

		private static List<XlsxRow> XlsxRows { get; set; } = new List<XlsxRow>();

		[Query(IsDefault = true)]
		public IQueryable<XlsxRow> GetXlsxRows()
		{
			return XlsxRows.AsQueryable();
		}

		[Query]
		public IQueryable<XlsxRow> GetXlsxRowsById(Guid? id)
		{
			XlsxBytes xlsxBytes = null;
			XlsxBytes.TryGetValue(id.Value, out xlsxBytes);

			using (MemoryStream mem = new MemoryStream())
			{
				mem.Write(xlsxBytes.Bytes, 0, (int)xlsxBytes.Bytes.Length);
				using (var sheet = SpreadsheetDocument.Open(mem, false))
				{
					sheet.Close();
				}
				mem.Close();
			}

			return XlsxRows.AsQueryable();
		}
	}
}
