using Microsoft.LightSwitch;
using System.Text;
using System.Linq;
using System.Collections.Generic;
using System;

namespace LightSwitchApplication
{
	public partial class XlsxRow
	{
		partial void Column0_Compute(ref string result)
		{
			result = this.XlsxCells?.ToArray()[0]?.Value;

		}
		partial void Column1_Compute(ref string result)
		{
			result = this.XlsxCells?.ToArray()[1]?.Value;

		}
		partial void Column2_Compute(ref string result)
		{
			result = this.XlsxCells?.ToArray()[2]?.Value;

		}
		partial void Column3_Compute(ref string result)
		{
			result = this.XlsxCells?.ToArray()[3]?.Value;

		}
		partial void Column4_Compute(ref string result)
		{
			result = this.XlsxCells?.ToArray()[4]?.Value;

		}
		partial void Column5_Compute(ref string result)
		{
			result = this.XlsxCells?.ToArray()[5]?.Value;

		}
		partial void Column6_Compute(ref string result)
		{
			result = this.XlsxCells?.ToArray()[6]?.Value;

		}
		partial void Column7_Compute(ref string result)
		{
			result = this.XlsxCells?.ToArray()[7]?.Value;

		}
		partial void Column8_Compute(ref string result)
		{
			result = this.XlsxCells?.ToArray()[8]?.Value;

		}
		partial void Column9_Compute(ref string result)
		{
			result = this.XlsxCells?.ToArray()[9]?.Value;

		}
		partial void Column10_Compute(ref string result)
		{
			result = this.XlsxCells?.ToArray()[10]?.Value;

		}
		//partial void Column11_Compute(ref string result)
		//{
		//	result = this.XlsxCells?.ToArray()[0]?.Value;

		//}
		//partial void Column12_Compute(ref string result)
		//{
		//	result = this.XlsxCells?.ToArray()[0]?.Value;

		//}
		//partial void Column13_Compute(ref string result)
		//{
		//	result = this.XlsxCells?.ToArray()[0]?.Value;

		//}
	}
}