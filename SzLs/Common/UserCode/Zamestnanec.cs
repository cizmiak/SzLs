using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
namespace LightSwitchApplication
{
    public partial class Zamestnanec
    {
        partial void CeleMeno_Compute(ref string result)
        {
            // Set result to the desired field value
            result = this.Priezvisko + " " + this.Meno;

        }
    }
}
