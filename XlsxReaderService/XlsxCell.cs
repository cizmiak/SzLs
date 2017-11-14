using System;
using System.ComponentModel.DataAnnotations;

namespace XlsxReaderService
{
	public class XlsxCell
	{
		[Key]
		public Guid Id { get; set; }
		public string Value { get; set; }
		public int ColumnId { get; set; }
		public Guid XlsxRowId { get; set; }

		[Association("XlsxCell_XlsxRow", "XlsxRowId", "Id", IsForeignKey = true)]
		public XlsxRow XlsxRow { get; set; }
		
	}
}
