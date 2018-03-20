using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel.DomainServices.Server;
using System.Text;
using System.Threading.Tasks;

namespace XlsxReaderService
{
	public class XlsxSheet
	{
		[Key]
		
		public Guid Id { get; set; }
		
		public string Name { get; set; }

		[Include]
		[Association("XlsxRow_XlsxSheet", "Id", "XlsxSheetId")]
		public ICollection<XlsxRow> XlsxRows { get; set; }
	}
}
