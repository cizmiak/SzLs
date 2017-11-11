using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
namespace LightSwitchApplication
{
    public partial class Posluchac
    {
		partial void CeleMeno_Compute(ref string result)
		{
			var titulPostfix = string.IsNullOrEmpty(this.Titul) ? "" : ", " + this.Titul;
			result = this.Priezvisko + " " + this.Meno + titulPostfix;
		}
	}
}