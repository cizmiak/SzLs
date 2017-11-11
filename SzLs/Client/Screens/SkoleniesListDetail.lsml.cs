using Microsoft.LightSwitch;
using Microsoft.LightSwitch.Presentation;
using Microsoft.LightSwitch.Presentation.Extensions;
using System;
using System.Linq;
using System.Collections.Generic;
using System.Windows.Controls;
using System.Windows.Threading;

namespace LightSwitchApplication
{
    public partial class SkoleniesListDetail
    {
		private string ReportServerUrl { get; set; }
        private SkolenieVysledok PredvolenyVysledok { get; set; }

		partial void SkoleniesListDetail_InitializeDataWorkspace(List<IDataService> saveChangesTo)
		{
			this.NasledujucePo = DateTime.Today;

			ReportServerUrl = getKonfiguracnaHodnota("ReportServerURL");
			string predvolenyVysledok = getKonfiguracnaHodnota("PredvolenyVysledokSkolenia");

			PredvolenyVysledok = this.DataWorkspace.SpravaZmluvData.SkolenieVysledoks
				.Where(sv => sv.Nazov == predvolenyVysledok)
				.FirstOrDefault();

			int pocetOtazok = 10;
			int.TryParse(getKonfiguracnaHodnota("PredvolenyGenerovanyPocetOtazok"), out pocetOtazok);
			this.PocetOtazok = pocetOtazok;
		}

        partial void SkoleniesListDetail_Created()
        {
			this.FindControl("Typ").ControlAvailable += Application.updateSourceAfterLastKeyUp;
			this.FindControl("Druh").ControlAvailable += Application.updateSourceAfterLastKeyUp;
			this.FindControl("Organizacia5").ControlAvailable += Application.updateSourceAfterLastKeyUp;
			this.FindControl("Zmluva2").ControlAvailable += Application.updateSourceAfterLastKeyUp;
			this.FindControl("Lektor").ControlAvailable += Application.updateSourceAfterLastKeyUp;
		}

        private string getKonfiguracnaHodnota(string nastavenie)
        {
            return this.DataWorkspace.SpravaZmluvData
                .KonfiguracnaHodnota(nastavenie).FirstOrDefault().Hodnota;
        }

        private string getReportUrl(string format)
        {
            return string.Format(
                "{0}?/{1}&rs:ClearSession=true&rs:Command=Render&rs:Format={2}&SkolenieID={3}"
                , ReportServerUrl
                , Report.Hodnota
                , format
				, Skolenies.SelectedItem.ID
                );
        }

        partial void ZaradPosluchaca_Execute()
        {
			SkoleniePosluchac zaradenyPosluchac = SkoleniePosluchacs.AddNew();
			zaradenyPosluchac.Posluchac = PosluchaciNezaradeni.SelectedItem;
            zaradenyPosluchac.SkolenieVysledok = PredvolenyVysledok;
			this.Save();
        }

        partial void VyradPosluchaca_Execute()
        {
            SkoleniePosluchacs.SelectedItem.Delete();
			this.Save();
        }

		partial void ZrusFiltre_Execute()
		{
			this.NasledujucePo = null;
			this.Typ = null;
			this.Druh = null;
			this.Organizacia = null;
			this.Zmluva = null;
			this.Lektor = null;
		}

        partial void OtvoritReport_Execute()
        {
            Application.navigateUri(getReportUrl("HTML4.0"));
        }

        partial void ExportDoWordu_Execute()
        {
            Application.navigateUri(getReportUrl("WORD"));
        }

        partial void ExportDoPDF_Execute()
        {
            Application.navigateUri(getReportUrl("PDF"));
        }

		partial void SkoleniePosluchacsAddNew_Execute()
		{
			SkoleniePosluchac zaradovanyPosluchac = SkoleniePosluchacs.AddNew();
			zaradovanyPosluchac.Posluchac = this.DataWorkspace.SpravaZmluvData.Posluchacs.AddNew();
			zaradovanyPosluchac.Posluchac.Organizacia = Skolenies.SelectedItem.Organizacia;
			zaradovanyPosluchac.SkolenieVysledok = PredvolenyVysledok;
		}

		partial void SkoleniesListDetail_Saved()
		{
			PosluchaciNezaradeni.Refresh();
		}

		partial void CopySkolenie_Execute()
		{
			Skolenie selectedSkolenie = Skolenies.SelectedItem;
			if (selectedSkolenie != null)
			{
				Skolenie selectedSkolenieCopy = Skolenies.AddNew();
				foreach (var property in selectedSkolenie.Details.Properties.All())
				{
					if (!property.IsReadOnly)
					{
						selectedSkolenieCopy.Details.Properties[property.Name].Value = property.Value;
					}
				}
				selectedSkolenieCopy.Nazov += string.Format("(Kopia, ID={0})", selectedSkolenie.ID);
				foreach (var skoleniePosluchac in selectedSkolenie.SkoleniePosluchacs)
				{
					SkoleniePosluchac skoleniePosluchacCopy = selectedSkolenieCopy.SkoleniePosluchacs.AddNew();
					skoleniePosluchacCopy.Posluchac = skoleniePosluchac.Posluchac;

					foreach (var property in skoleniePosluchac.Details.Properties.All())
					{
						if (!property.IsReadOnly)
						{
							skoleniePosluchacCopy.Details.Properties[property.Name].Value = property.Value;
						}
					}
				}
			}
		}

		partial void CopySkolenie_CanExecute(ref bool result)
		{
			result = (Skolenies.SelectedItem != null);
		}

		partial void GenerovatOtazky_CanExecute(ref bool result)
		{
			result = Skolenies.SelectedItem != null &&
				Skolenies.SelectedItem.SkolenieTyp != null &&
				Skolenies.SelectedItem.SkoleniePreKoho != null &&
				this.SkolenieOtazkas.Count == 0;
		}

		partial void GenerovatOtazky_Execute()
		{
			this.PocetOtazok = 6;
			this.OpenModalWindow("GenerovanieOtazok");
		}

		partial void GenerujOtazky_Execute()
		{
			var otazkyPreSkolenie = this.Otazkas.AsEnumerable().ToArray();

			List<int> pouziteIndexy = new List<int>();
			int celkovyPocetOtazok = otazkyPreSkolenie.Count();
			int pocetNaGenerovanie = this.PocetOtazok < celkovyPocetOtazok ? this.PocetOtazok : celkovyPocetOtazok;

			for (int i = 1; i <= pocetNaGenerovanie; i++)
			{
				SkolenieOtazka skolenieOtazka = this.SkolenieOtazkas.AddNew();
				skolenieOtazka.Poradie = i;
				skolenieOtazka.Skolenie = this.Skolenies.SelectedItem;

				int index;
				do
				{
					index = (new Random()).Next(celkovyPocetOtazok);
				}
				while (pouziteIndexy.Contains(index));
				
				skolenieOtazka.Otazka = otazkyPreSkolenie[index];
				pouziteIndexy.Add(index);
			}

			this.CloseModalWindow("GenerovanieOtazok");
			this.SkolenieOtazkas.Refresh();
		}
    }
}
