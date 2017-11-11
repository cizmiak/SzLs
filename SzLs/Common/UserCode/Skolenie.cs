using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
namespace LightSwitchApplication
{
    public partial class Skolenie
    {
		partial void Notifikovany_Validate(EntityValidationResultsBuilder results)
		{
			if (this.Notifikovany == null)
			{
				results.AddPropertyError("Notifikovany musi byt vyplneny!");
			}
		}

		partial void Lektor_Changed()
		{
			if (this.PredsedaKomisie == null)
			{
				this.PredsedaKomisie = this.Lektor;
			}
		}
	}
}
