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
	}
}