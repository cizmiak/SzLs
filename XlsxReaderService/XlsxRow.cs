using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Runtime.Serialization;
using System.ServiceModel.DomainServices.Server;

namespace XlsxReaderService
{
	public class XlsxRow
	{
		[Key]	
		public Guid Id { get; set; }
		
		public bool IsHeader { get; set; }
		
		public int RowId { get; set; }
		
		public Guid XlsxSheetId { get; set; }

		[Include]
		[Association("XlsxCell_XlsxRow", "Id", "XlsxRowId")]	
		public ICollection<XlsxCell> XlsxCells { get; set; }

		[Include]
		[Association("XlsxRow_XlsxSheet", "XlsxSheetId", "Id", IsForeignKey = true)]	
		public XlsxSheet XlsxSheet { get; set; }
	}
}
