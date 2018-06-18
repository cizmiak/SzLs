using System;
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
			CreateXlsxSheets(xlsxBytes);
		}

		[Insert]
		public void InsertXlsxBytes(XlsxBytes xlsxBytes)
		{
			CreateXlsxSheets(xlsxBytes);
		}

		[Delete]
		public void DeleteXlsxBytes(XlsxBytes xlsxBytes)
		{
			XlsxBytes.TryRemove(xlsxBytes.Id, out xlsxBytes);

			List<XlsxSheet> dummy = null;
			XlsxSheets.TryRemove(xlsxBytes.Id, out dummy);
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
			List<XlsxSheet> xlsxSheets = null;
			if (xlsxId.HasValue && XlsxSheets.TryGetValue(xlsxId.Value, out xlsxSheets))
			{
				return xlsxSheets.AsQueryable();
			}
			return null;
			
		}

		private static void CreateXlsxSheets(XlsxBytes xlsxBytes)
		{
			XlsxBytes.AddOrUpdate(xlsxBytes.Id, xlsxBytes, (k, v) => xlsxBytes);

			if (xlsxBytes == null)
				return;

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

						if (!xlsxSheet.Name.StartsWith("import"))
							continue;

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
							foreach (var cell in row.Descendants<DocumentFormat.OpenXml.Spreadsheet.Cell>())
							{
								var columnId = WorksheetAccessor.GetColumnNumber(cell.CellReference);

								string value = null;
								try
								{
									value = WorksheetAccessor
										.GetCellValue(spreadSheetDoc, workSheetpart, columnId, xlsxRow.RowId)
										.ToString();
								}
								catch (Exception e)
								{
									value = value ?? e.Message;
								}

								xlsxCells.Add(new XlsxCell()
								{
									Id = Guid.NewGuid(),
									Value = value,
									ColumnId = columnId,
									XlsxRowId = xlsxRow.Id,
									XlsxRow = xlsxRow
								});
							}

							xlsxRow.XlsxCells = xlsxCells;
							xlsxRows.Add(xlsxRow);
						}

						xlsxSheet.XlsxRows = xlsxRows;
						xlsxSheets.Add(xlsxSheet);
					}
					spreadSheetDoc.Close();
				}
				mem.Close();
			}

			XlsxSheets.AddOrUpdate(xlsxBytes.Id, xlsxSheets, (k,v) => xlsxSheets);
		}
		#endregion

		#region XlsxRows
		[Query(IsDefault = true)]
		public IQueryable<XlsxRow> GetXlsxRows()
		{
			return XlsxSheets
				.SelectMany(kvPair => kvPair.Value)
				.SelectMany(xlsxSheet => xlsxSheet.XlsxRows)
				.AsQueryable();
		}

		[Update]
		public void UpdateXlsxRow(XlsxRow xlsxRow) { }
		#endregion

		#region XlsxCells
		[Query(IsDefault = true)]
		public IQueryable<XlsxCell> GetXlsxCells()
		{
			return XlsxSheets
				.SelectMany(kvPair => kvPair.Value)
				.SelectMany(xlsxSheet => xlsxSheet.XlsxRows)
				.SelectMany(r => r.XlsxCells)
				.AsQueryable();
		}
		#endregion
	}
}
