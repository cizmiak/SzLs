using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;

namespace LightSwitchApplication
{
    public partial class Uloha
    {
		partial void UvodnaPraca_Changed()
		{
			if(this.UvodnaPraca != null)
			{
				this.Poradie = this.UvodnaPraca.Poradie;
				this.Nazov = this.UvodnaPraca.Nazov;
				this.Popis = this.UvodnaPraca.Popis;
			}
		}

        partial void VyrieseneDna_Changed()
        {
            string ulohaStavVyrieseneString =
				this.DataWorkspace.SpravaZmluvData.KonfiguracnaHodnota("UlohaStavVyriesene").FirstOrDefault().Hodnota;
            if (this.VyrieseneDna != null && (this.UlohaStav == null || this.UlohaStav.Nazov != ulohaStavVyrieseneString))
            {
				this.UlohaStav = this.DataWorkspace.SpravaZmluvData.UlohaStavs.Where(us => us.Nazov == ulohaStavVyrieseneString).FirstOrDefault();
            }
        }
	}
}
