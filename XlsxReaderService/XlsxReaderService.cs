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
		private static ConcurrentDictionary<Guid, XlsxBytes> XlsxBytes =>
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

		#region XlsxRows
		private static List<XlsxRow> XlsxRows { get; set; }

		[Query(IsDefault = true)]
		public IQueryable<XlsxRow> GetXlsxRows()
		{
			if (XlsxRows == null)
			{
				var row1 = new XlsxRow() { Id = Guid.NewGuid(), IsHeader = true };
				row1.XlsxCells = new List<XlsxCell>()
					{
						new XlsxCell()
						{
							Id = Guid.NewGuid(),
							Value = "Header 1",
							ColumnId = 1,
							XlsxRowId = row1.Id,
							XlsxRow = row1
						},
						new XlsxCell()
						{
							Id = Guid.NewGuid(),
							Value = "Header 2",
							ColumnId = 2,
							XlsxRowId = row1.Id,
							XlsxRow = row1
						},
					};

				var row2 = new XlsxRow() { Id = Guid.NewGuid(), IsHeader = false };
				row2.XlsxCells = new List<XlsxCell>()
					{
						new XlsxCell()
						{
							Id = Guid.NewGuid(),
							Value = "Cell 1",
							ColumnId = 1,
							XlsxRowId = row2.Id,
							XlsxRow = row2
						},
						new XlsxCell()
						{
							Id = Guid.NewGuid(),
							Value = "Cell 2",
							ColumnId = 2,
							XlsxRowId = row2.Id,
							XlsxRow = row2
						},
					};

				XlsxRows = new List<XlsxRow>();
				XlsxRows.Add(row1);
				XlsxRows.Add(row2);
			}

			return XlsxRows.AsQueryable();
		}

		[Query]
		public IQueryable<XlsxRow> GetXlsxRowsById(Guid? id)
		{
			if (!id.HasValue)
				return null;

			XlsxBytes xlsxBytes = null;
			XlsxBytes.TryGetValue(id.Value, out xlsxBytes);

			using (MemoryStream mem = new MemoryStream())
			{
				mem.Write(xlsxBytes.Bytes, 0, (int)xlsxBytes.Bytes.Length);
				using (var spreadSheet = SpreadsheetDocument.Open(mem, false))
				{
					//spreadSheet.ta
					foreach(var workSheetpart in spreadSheet.WorkbookPart.WorksheetParts)
					{
						//workSheetpart.Worksheet.
					}
					spreadSheet.Close();
				}
				mem.Close();
			}

			return XlsxRows.AsQueryable();
		}
		#endregion

		#region XlsxCells
		private static List<XlsxCell> XlsxCells => new List<XlsxCell>();

		[Query(IsDefault = true)]
		public IQueryable<XlsxCell> GetXlsxCells()
		{
			return XlsxRows.SelectMany(r => r.XlsxCells).AsQueryable();
		}
		#endregion
	}
}
