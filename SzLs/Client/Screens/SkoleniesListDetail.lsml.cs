using Microsoft.LightSwitch;
using Microsoft.LightSwitch.Presentation;
using Microsoft.LightSwitch.Presentation.Extensions;
using System;
using System.Linq;
using System.Collections.Generic;
using System.Windows.Controls;
using Microsoft.LightSwitch.Threading;
using System.Windows;

namespace LightSwitchApplication
{
	public partial class SkoleniesListDetail
	{
		private string ReportServerUrl;
		private SkolenieVysledok PredvolenyVysledok;
		private XlsxSheet xlsxSheet;
		private List<Organizacia> organizacie;
		private List<PracovneZaradenie> pracovneZaradenia;

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
			this.FindControl("XlsxImport").ControlAvailable += XlsxImport_ControlAvailable;
		}

		partial void SkoleniesListDetail_Saved()
		{
			PosluchaciNezaradeni.Refresh();
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

		#region Xlsx Import

		private void XlsxImport_ControlAvailable(object sender, ControlAvailableEventArgs e)
		{
			((Button)e.Control).Click += XlsxImport_Click;
		}

		private void XlsxImport_Click(object sender, System.Windows.RoutedEventArgs e)
		{
			if (this.Skolenies.SelectedItem == null)
			{
				this.showMessage("Nie je vybrate ziadne skolenie.");
				return;
			}

			byte[] bytes = null;

			Dispatchers.Main.Invoke(() => {
				var dialog = new OpenFileDialog();
				dialog.Filter = "Excel(*.xlsx)|*.xlsx";

				if (dialog.ShowDialog() == true)
				{
					using (var fileStream = dialog.File.OpenRead())
					{
						int fileLength = (int)fileStream.Length;
						if (fileStream.Length > 0)
						{
							bytes = new byte[fileLength];
							fileStream.Read(bytes, 0, fileLength);
						}

						fileStream.Close();
					}
				}
			});

			
			
			this.Details.Dispatcher.BeginInvoke(() =>
			{
				XlsxByte xlsxByte = null;
				try
				{
					var id = Guid.NewGuid();

					xlsxByte = this.DataWorkspace.XlsxReaderServiceData.XlsxBytes.AddNew();
					xlsxByte.Id = id;
					xlsxByte.Bytes = bytes;
					this.DataWorkspace.XlsxReaderServiceData.SaveChanges();

					this.xlsxSheet = null;
					this.xlsxSheet = this.DataWorkspace.XlsxReaderServiceData
						.GetXlsxSheetsById(id)
						.FirstOrDefault();

					this.xlsxDataReady();
				}
				catch (Exception exception)
				{
					var innerException = exception.InnerException != null
						? exception.InnerException.Message
						: string.Empty;
					this.showMessage($"{exception.Message}\n{innerException}\n{exception.StackTrace}");
				}
				finally
				{
					if (xlsxByte != null)
						xlsxByte.Delete();
					this.DataWorkspace.XlsxReaderServiceData.SaveChanges();
				}
			});
		}

		private void xlsxDataReady()
		{
			if (this.xlsxSheet == null)
			{
				this.showMessage("Nazov excel sheetu, ktory chcete naimportovat, sa musi zacinat slovom 'import'.");
				return;
			}

			var headers = this.GetHeaders();
			var headerRow = this.GetHeaderRow(this.xlsxSheet, headers);
			if (headerRow == null)
			{
				var message = "Nepodarilo sa najst hlavickovy riadok.";
				message += "\nPovolene nazvy stlpcov su:\n";
				message += string.Join("\n", headers);
				this.showMessage(message);
				return;
			}

			this.parseXlsxData(this.xlsxSheet, headerRow, headers);
		}

		private void showMessage(string message)
		{
			Dispatchers.Main.Invoke(() =>
				MessageBox.Show(message));
		}

		private void parseXlsxData(XlsxSheet xlsxSheet, XlsxRow headerRow, IEnumerable<string> headers)
		{
			var xlsxHeaders = headerRow.XlsxCells.Select(c => c.Value).ToArray();
			var intersectHeaders = headers.Intersect(xlsxHeaders);

			var processedXlsxRows = 0;
			var rowsAlreadyInDb = 0;
			var rowsAlreadyImported = 0;
			var rowsImported = 0;

			if (this.organizacie == null || this.organizacie.Count < this.DataWorkspace.SpravaZmluvData
				.Organizacie
				.GetQuery().Execute().Count())
			{
				this.organizacie = this.DataWorkspace.SpravaZmluvData.Organizacie.GetQuery().Execute().ToList();
			}

			if (this.pracovneZaradenia == null || this.pracovneZaradenia.Count < this.DataWorkspace.SpravaZmluvData
				.PracovneZaradenies
				.GetQuery().Execute().Count())
			{
				this.pracovneZaradenia = this.DataWorkspace.SpravaZmluvData.PracovneZaradenies
					.GetQuery().Execute().ToList();
			}

			foreach (var row in xlsxSheet.XlsxRows)
			{
				if (row.RowId <= headerRow.RowId)
					continue;

				var cells = row.XlsxCells.Select(c => c.Value).ToArray();
				var posluchac = this.DataWorkspace.SpravaZmluvData.Posluchacs.AddNew();
				for (int i = 0; i < xlsxHeaders.Length; i++)
				{
					if (!intersectHeaders.Contains(xlsxHeaders[i]))
						continue;

					if (i >= cells.Length)
						continue;

					var propertyType = posluchac.Details.Properties[xlsxHeaders[i]].PropertyType;

					if (propertyType == typeof(string))
						posluchac.Details.Properties[xlsxHeaders[i]].Value = cells[i];
					else if (propertyType == typeof(bool))
						posluchac.Details.Properties[xlsxHeaders[i]].Value = bool.Parse(cells[i]);
					else if (propertyType == typeof(DateTime))
						posluchac.Details.Properties[xlsxHeaders[i]].Value = DateTime.Parse(cells[i]);

					if (xlsxHeaders[i] == "Organizacia")
					{
						var organizacia = this.organizacie.FirstOrDefault(o => o.Referencia == (cells[i]));
						organizacia = organizacia ?? this.organizacie.FirstOrDefault(o => o.Nazov == (cells[i]));
						posluchac.Organizacia = organizacia;
					}

					if (xlsxHeaders[i] == "PracovneZaradenie")
					{
						var pracovneZaradenie = this.pracovneZaradenia.FirstOrDefault(pz => pz.Nazov == cells[i]);

						if (pracovneZaradenie == null)
						{
							pracovneZaradenie = this.DataWorkspace.SpravaZmluvData.PracovneZaradenies.AddNew();
							pracovneZaradenia.Add(pracovneZaradenie);
							pracovneZaradenie.Nazov = cells[i];
							posluchac.PracovneZaradenie = pracovneZaradenie;
						}
					}
				}

				if (string.IsNullOrEmpty(posluchac.Meno) && string.IsNullOrEmpty(posluchac.Priezvisko))
				{
					posluchac.Delete();
					continue;
				}

				processedXlsxRows++;

				var selectedSkolenie = this.Skolenies.SelectedItem;

				if (posluchac.Organizacia == null)
					posluchac.Organizacia = selectedSkolenie.Organizacia;

				var savedPosluchac = this.DataWorkspace.SpravaZmluvData.PosluchacFromDb(
					posluchac.Meno,
					posluchac.Priezvisko,
					posluchac.Titul,
					posluchac.Organizacia?.ID);

				if (savedPosluchac != null)
				{
					posluchac.Delete();
					posluchac = savedPosluchac;
					rowsAlreadyInDb++;
				}

				var posluchacAlreadyImported = selectedSkolenie.SkoleniePosluchacs
					.SingleOrDefault(sp =>
						sp.Posluchac.Meno == posluchac.Meno &&
						sp.Posluchac.Priezvisko == posluchac.Priezvisko &&
						sp.Posluchac.Titul == posluchac.Titul &&
						sp.Posluchac.Organizacia?.ID == posluchac.Organizacia?.ID);

				if (posluchacAlreadyImported == null)
				{
					var skoleniePosluchac = selectedSkolenie.SkoleniePosluchacs.AddNew();
					skoleniePosluchac.Skolenie = selectedSkolenie;
					skoleniePosluchac.Posluchac = posluchac;
					skoleniePosluchac.SkolenieVysledok = PredvolenyVysledok;
					rowsImported++;
				}
				else
				{
					rowsAlreadyImported++;
				}
			}

			var message = $"Pocet precitanych riadkov z Excelu: {processedXlsxRows}.\n";
			//message += $"Pocet najdenych riadkov v databaze: {rowsAlreadyInDb}";
			message += $"Pocet nenaimportovanych riadokov kvoli duplicite: {rowsAlreadyImported}.\n";
			message += $"Pocet naimportovanych riadkov: {rowsImported}";
			this.showMessage(message);
		}

		private IEnumerable<string> GetHeaders()
		{
			var posluchacHeaders = this.DataWorkspace.SpravaZmluvData
				.Posluchacs.Details.EntityType
				.GetProperties()
				.Where(p => p.CanWrite)
				.Select(p => p.Name);
			var skoleniePosluchacHeaders = this.DataWorkspace.SpravaZmluvData
				.SkoleniePosluchacs.Details.EntityType
				.GetProperties()
				.Where(p => p.CanWrite)
				.Select(p => p.Name);
			var headers = posluchacHeaders
				.Concat(skoleniePosluchacHeaders)
				.Distinct()
				.Where(h => !h.StartsWith("Posluchac") && !h.StartsWith("Skolenie"));
			return headers;
		}

		private XlsxRow GetHeaderRow(XlsxSheet xlsxSheet, IEnumerable<string> headers)
		{
			foreach (var row in xlsxSheet.XlsxRows)
			{
				var foundHeaderCount = 0;
				foreach (var cell in row.XlsxCells)
				{
					if (headers.Contains(cell.Value))
						foundHeaderCount++;

					if (foundHeaderCount > 1)
					{
						row.IsHeader = true;
						return row;
					}
				}
			}

			return null;
		}

		#endregion

		#region Posluchac

		partial void ZaradPosluchaca_Execute()
		{
			SkoleniePosluchac zaradenyPosluchac = SkoleniePosluchacs.AddNew();
			zaradenyPosluchac.Posluchac = PosluchaciNezaradeni.SelectedItem;
			zaradenyPosluchac.SkolenieVysledok = PredvolenyVysledok;

			var currentSkolenie = this.Skolenies.SelectedItem;
			var lastSkoleniePosluchac = this.DataWorkspace.SpravaZmluvData.SkoleniePosluchacs
				.Where(sp =>
					sp.PosluchacID == zaradenyPosluchac.Posluchac.ID
					&&
					sp.Skolenie.SkolenieTyp.ID == currentSkolenie.SkolenieTyp.ID)
				.OrderByDescending(sp => sp.Skolenie.Uskutocnene)
				.Execute()
				.FirstOrDefault();

			zaradenyPosluchac.CopyFrom(lastSkoleniePosluchac);

			this.Save();
		}

		partial void VyradPosluchaca_Execute()
		{
			SkoleniePosluchacs.SelectedItem.Delete();
			this.Save();
		}

		partial void ZaradPosluchaca_CanExecute(ref bool result)
		{
			result = PosluchaciNezaradeni.SelectedItem != null;
		}

		partial void VyradPosluchaca_CanExecute(ref bool result)
		{
			result = SkoleniePosluchacs.SelectedItem != null;
		}

		partial void SkoleniePosluchacsAddNew_Execute()
		{
			SkoleniePosluchac zaradovanyPosluchac = SkoleniePosluchacs.AddNew();
			zaradovanyPosluchac.Posluchac = this.DataWorkspace.SpravaZmluvData.Posluchacs.AddNew();
			zaradovanyPosluchac.Posluchac.Organizacia = Skolenies.SelectedItem.Organizacia;
			zaradovanyPosluchac.SkolenieVysledok = PredvolenyVysledok;
		}
		#endregion

		#region Reports

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

		#endregion

		#region Copy

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

					skoleniePosluchacCopy.CopyFrom(skoleniePosluchac);
				}
			}
		}

		partial void CopySkolenie_CanExecute(ref bool result)
		{
			result = (Skolenies.SelectedItem != null);
		}

		#endregion

		#region Questions

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

		#endregion

		#region CisloPreukazu

		private string getNextCisloPreukazu()
		{
			var selectedSkolenie = this.Skolenies.SelectedItem;
			if (selectedSkolenie != null && selectedSkolenie.SkolenieTyp != null)
			{
				var maska = selectedSkolenie.SkolenieTyp.MaskaCislaPreukazu;
				if (maska != null)
				{
					var lastCisloPreukazu = this.DataWorkspace.SpravaZmluvData.SkoleniePosluchacs
						.Where(sp => sp.Skolenie.SkolenieTyp.ID == selectedSkolenie.SkolenieTyp.ID)
						.Execute()
						.Where(sp => sp.CisloPreukazu != null && sp.CisloPreukazu.Contains(maska))
						.Select(sp => sp.CisloPreukazu)
						.OrderByDescending(cp => cp)
						.FirstOrDefault();

					lastCisloPreukazu = lastCisloPreukazu ?? string.Format("{0}{1}000", maska, DateTime.Now.Year);

					var lastCisloString = lastCisloPreukazu.Replace(maska, "");
					decimal lastCislo;
					if (decimal.TryParse(lastCisloString, out lastCislo))
						return string.Format("{0}{1:F0}", maska, lastCislo + 1);
				}
			}
			return null;
		}

		partial void GenerujCisloPreukazu_Execute()
		{
			this.SkoleniePosluchacs.SelectedItem.CisloPreukazu = this.getNextCisloPreukazu();

		}

		partial void GenerujCisloPreukazu_CanExecute(ref bool result)
		{
			result = this.Skolenies.SelectedItem != null &&
				this.Skolenies.SelectedItem.SkolenieTyp != null &&
				this.SkoleniePosluchacs.SelectedItem != null &&
				string.IsNullOrEmpty(this.SkoleniePosluchacs.SelectedItem.CisloPreukazu);
		}

		#endregion
	}
}
