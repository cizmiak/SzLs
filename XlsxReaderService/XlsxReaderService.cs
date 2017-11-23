﻿using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.ServiceModel.DomainServices.Server;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Spreadsheet;
using OpenXmlPowerTools;

namespace XlsxReaderService
{
	// NOTE: You can use the "Rename" command on the "Refactor" menu to change the class name "Service1" in both code and config file together.
	public class XlsxReaderService : DomainService
	{
		private static ConcurrentDictionary<Guid, XlsxBytes> XlsxBytes { get; } =
			new ConcurrentDictionary<Guid, XlsxBytes>();

		private static ConcurrentDictionary<Guid, List<XlsxSheet>> XlsxSheets { get; } =
			new ConcurrentDictionary<Guid, List<XlsxSheet>>();
		
		#region XlsxBytes
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
			XlsxBytes.TryAdd(xlsxBytes.Id, xlsxBytes);
		}

		[Delete]
		public void DeleteXlsxBytes(XlsxBytes xlsxBytes)
		{
			XlsxBytes.TryRemove(xlsxBytes.Id, out xlsxBytes);
		}
		#endregion

		#region XlsxSheets
		[Query(IsDefault = true)]
		public IQueryable<XlsxSheet> GetXlsxSheets()
		{
			return XlsxSheets.SelectMany(kvPair => kvPair.Value).AsQueryable();
		}

		[Query]
		public IQueryable<XlsxSheet> GetXlsxSheetsById(Guid? xlsxId)
		{
			if (!xlsxId.HasValue)
				return null;

			XlsxBytes xlsxBytes = null;
			XlsxBytes.TryGetValue(xlsxId.Value, out xlsxBytes);
			if (xlsxBytes == null)
				return null;
			
			var xlsxSheets = new List<XlsxSheet>();

			using (MemoryStream mem = new MemoryStream())
			{
				mem.Write(xlsxBytes.Bytes, 0, (int)xlsxBytes.Bytes.Length);
				using (var spreadSheetDoc = SpreadsheetDocument.Open(mem, false))
				{
					foreach (var workSheetpart in spreadSheetDoc.WorkbookPart.WorksheetParts)
					{
						var xlsxSheet = new XlsxSheet()
						{
							Id = Guid.NewGuid(),
							Name = SpreadsheetDocumentManager.GetSheetName(workSheetpart, spreadSheetDoc)
						};

						var xlsxRows = new List<XlsxRow>();
						foreach (var row in workSheetpart.Worksheet.Descendants<DocumentFormat.OpenXml.Spreadsheet.Row>())
						{
							var xlsxRow = new XlsxRow()
							{
								Id = Guid.NewGuid(),
								RowId = (int)(uint)row.RowIndex,
								IsHeader = false,
								XlsxSheetId = xlsxSheet.Id,
								XlsxSheet = xlsxSheet
							};

							var xlsxCells = new List<XlsxCell>();
							var i = 0;
							foreach (var cell in row.Descendants<DocumentFormat.OpenXml.Spreadsheet.Cell>())
							{
								i++;
								xlsxCells.Add(new XlsxCell()
								{
									Id = Guid.NewGuid(),
									Value = WorksheetAccessor.GetCellValue(spreadSheetDoc, workSheetpart, i, xlsxRow.RowId).ToString(),
									ColumnId = i,
									XlsxRowId = xlsxRow.Id,
									XlsxRow = xlsxRow
								});
							}

							xlsxRow.XlsxCells = xlsxCells;
						}

						xlsxSheet.XlsxRows = xlsxRows;

						//var dimension = workSheetpart.Worksheet.SheetDimension.Reference.Value;
						//var range = SmlDataRetriever.RetrieveRange(spreadSheetDoc, xlsxSheet.Name, dimension);
						xlsxSheets.Add(xlsxSheet);
					}
					spreadSheetDoc.Close();
				}
				mem.Close();
			}

			XlsxSheets.TryAdd(xlsxId.Value, xlsxSheets);
			return xlsxSheets.AsQueryable();
		}
		#endregion

		#region XlsxRows
		[Query(IsDefault = true)]
		public IQueryable<XlsxRow> GetXlsxRows()
		{
			return GetXlsxSheets().SelectMany(xlsxSheet => xlsxSheet.XlsxRows).AsQueryable();
		}
		#endregion

		#region XlsxCells
		[Query(IsDefault = true)]
		public IQueryable<XlsxCell> GetXlsxCells()
		{
			return GetXlsxRows().SelectMany(r => r.XlsxCells).AsQueryable();
		}
		#endregion
	}
}
