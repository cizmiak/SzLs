using Microsoft.LightSwitch.Presentation.Extensions;
using System;

namespace LightSwitchApplication
{
	public partial class Ponuky
	{
		partial void Odosli_CanExecute(ref bool result)
		{
			result = this.Offers.SelectedItem != null;
		}

		partial void Odosli_Execute()
		{
			this.Offers.SelectedItem.DatumOdoslania = DateTime.Now;
			this.Save();
		}

		partial void Ponuky_Activated()
		{
			this.FindControl("Cena").IsVisible = this.Application.IsCurrentUserAdministrator;

		}

		partial void NacitajZoSablony_CanExecute(ref bool result)
		{
			result = this.Offers.SelectedItem.EmailSablona != null;
		}

		partial void NacitajZoSablony_Execute()
		{
			this.Offers.SelectedItem.ReadFromEmailTemplate();
		}
	}
}