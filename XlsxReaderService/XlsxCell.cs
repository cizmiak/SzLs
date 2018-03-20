using System;
using System.ComponentModel.DataAnnotations;
using System.Runtime.Serialization;
using System.ServiceModel.DomainServices.Server;

namespace XlsxReaderService
{
	public class XlsxCell
	{
		[Key]	
		public Guid Id { get; set; }
		
		public string Value { get; set; }
		
		public int ColumnId { get; set; }
		
		public Guid XlsxRowId { get; set; }

		[Include]
		[Association("XlsxCell_XlsxRow", "XlsxRowId", "Id", IsForeignKey = true)]	
		public XlsxRow XlsxRow { get; set; }
		
	}
}
