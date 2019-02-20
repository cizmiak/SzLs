using System.Linq;
using Microsoft.LightSwitch;
using Microsoft.LightSwitch.Presentation.Extensions;

namespace LightSwitchApplication
{
	public partial class ZmluvasListDetail
	{
		partial void ZrusFiltre_Execute()
		{
			// Write your code here.
			this.Organizacia = null;
			this.Typ = null;
			this.Zodpovedny = null;
			this.Stav = null;

		}

		partial void ZmluvasListDetail_Created()
		{
			// Write your code here.
			Konfiguracia predvolenyFilterStavZmluvy = this.DataWorkspace.SpravaZmluvData
				.KonfiguracnaHodnota("PredvolenyFilterStavZmluvy").FirstOrDefault();

			this.Stav = this.ZmluvaStavs
				.FirstOrDefault(zmluvaStav => zmluvaStav.Nazov == predvolenyFilterStavZmluvy.Hodnota);

			this.UlohaTypVykon = this.DataWorkspace.SpravaZmluvData.UlohaTypVykon();
			this.UlohaTypUvodnaPraca = this.DataWorkspace.SpravaZmluvData.UlohaTypUvodnaPraca();
		}

		partial void UvodnaPraca_SelectionChanged()
		{
			Uloha uloha = UvodnaPraca.SelectedItem;
			if (uloha != null)
			{
				if (uloha.Zmluva == null)
				{
					uloha.Zmluva = this.Zmluvas.SelectedItem;
				}
				if (uloha.UlohaTyp == null)
				{
					uloha.UlohaTyp = this.UlohaTypUvodnaPraca;
				}
			}
		}

		partial void Vykon_SelectionChanged()
		{
			Uloha uloha = Vykon.SelectedItem;
			if (uloha != null)
			{
				if (uloha.Zmluva == null)
				{
					uloha.Zmluva = this.Zmluvas.SelectedItem;
				}
				if (uloha.UlohaTyp == null)
				{
					uloha.UlohaTyp = this.UlohaTypVykon;
				}
			}
		}

		partial void ZmluvasListDetail_Saved()
		{
			// Write your code here.
			UvodnaPraca.Refresh();
			Vykon.Refresh();

		}

		partial void ZmluvasListDetail_Activated()
		{
			this.FindControl("DohodnutaCena1").IsVisible = this.Application.IsCurrentUserAdministrator;
		}
	}
}
