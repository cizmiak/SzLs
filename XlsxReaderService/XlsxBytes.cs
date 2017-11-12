using System;
using System.ComponentModel.DataAnnotations;
using System.Runtime.Serialization;

namespace XlsxReaderService
{
	public class XlsxBytes
	{
		[Key]
		public Guid Id { get; set; }

		public byte[] Bytes { get; set; }
	}
}
