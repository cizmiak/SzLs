using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace XlsxReaderService
{
	public class XlsxRow
	{
		[Key]
		public Guid Id { get; set; }
		public bool IsHeader { get; set; }

		[Association("XlsxCell_XlsxRow", "Id", "XlsxRowId")]
		public List<XlsxCell> XlsxCells { get; set; }
	}
}
