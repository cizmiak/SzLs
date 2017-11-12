using System.ComponentModel.DataAnnotations;

namespace XlsxReaderService
{
	public class XlsxRow
	{
		[Key]
		public int Id { get; set; }
		public string Column1 { get; set; }
		public string Column2 { get; set; }
		public string Column3 { get; set; }
	}
}
