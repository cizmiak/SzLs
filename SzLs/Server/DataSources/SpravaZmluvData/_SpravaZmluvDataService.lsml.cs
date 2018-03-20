using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
using Microsoft.LightSwitch.Security.Server;
using Microsoft.LightSwitch.Security;
namespace LightSwitchApplication
{
	public partial class SpravaZmluvDataService
	{
		partial void PosluchaciNezaradeni_PreprocessQuery(int? OrganizaciaID, int? SkolenieID, int? MatkaID, ref IQueryable<Posluchac> query)
		{
			var zaradeniPosluchaci = this.SkoleniePosluchacs
				.Where(skoleniePosluchac => skoleniePosluchac.SkolenieID == (SkolenieID ?? -1))
				.Execute()
				.Select(skoleniePosluchac => skoleniePosluchac.Posluchac.ID);

			query = query.Where(posluchac => !zaradeniPosluchaci.Contains(posluchac.ID));
		}

		partial void UlohaTypVykon_PreprocessQuery(ref IQueryable<UlohaTyp> query)
		{
			Konfiguracia konfiguraciaTypUlohy = KonfiguracnaHodnota("ZmluvaVykonTypUlohy").FirstOrDefault();
			query = query.Where(ulohaTyp => ulohaTyp.Nazov == konfiguraciaTypUlohy.Hodnota);
		}

		partial void UlohaTypUvodnaPraca_PreprocessQuery(ref IQueryable<UlohaTyp> query)
		{
			Konfiguracia konfiguraciaTypUlohy = KonfiguracnaHodnota("ZmluvaUvodnaPracaTypUlohy").FirstOrDefault();
			query = query.Where(ulohaTyp => ulohaTyp.Nazov == konfiguraciaTypUlohy.Hodnota);
		}

		partial void UlohyVykon_PreprocessQuery(int? ZmluvaID, ref IQueryable<Uloha> query)
		{
			int VykonUlohaTypID = this.UlohaTypVykon().ID;
			query = query.Where<Uloha>(uloha => uloha.Zmluva.ID == ZmluvaID && uloha.UlohaTyp.ID == VykonUlohaTypID);
		}

		partial void UlohyUvodnaPraca_PreprocessQuery(int? ZmluvaID, ref IQueryable<Uloha> query)
		{
			int UvodnaPracaUlohaTypID = this.UlohaTypUvodnaPraca().ID;
			query = query.Where<Uloha>(uloha => uloha.Zmluva.ID == ZmluvaID && uloha.UlohaTyp.ID == UvodnaPracaUlohaTypID);
		}

		partial void Ulohy_Updating(Uloha entity)
		{
			entity.Upravovane = DateTime.Now;
			entity.ZamestnanecUpravil = this.ZamestnanecPodlaLoginu(this.Application.User.FullName);
		}

		partial void Ulohy_Inserting(Uloha entity)
		{
			entity.Vytvorene = DateTime.Now;
			entity.ZamestnanecUpravil = this.ZamestnanecPodlaLoginu(this.Application.User.FullName);
		} 

		partial void Zmluvy_Updating(Zmluva entity)
		{
			entity.PoslednaUprava = DateTime.Now;
			entity.Zamestnanec = this.ZamestnanecPodlaLoginu(this.Application.User.FullName);
		}

		partial void Zmluvy_Inserting(Zmluva entity)
		{
			entity.PoslednaUprava = DateTime.Now;
			entity.Zamestnanec = this.ZamestnanecPodlaLoginu(this.Application.User.FullName);
		}

		partial void Zmluvy_CanUpdate(ref bool result)
		{
			result = Zmluvy_CanEdit;
		}

		partial void Zmluvy_CanDelete(ref bool result)
		{
			result = IsCurrentUserAdministrator;
		}

		partial void Zmluvy_CanInsert(ref bool result)
		{
			result = Zmluvy_CanEdit;
		}

		Zamestnanec prihlasenyZamestnanec;
		public Zamestnanec PrihlasenyZamestnanec
		{
			get
			{
				if (prihlasenyZamestnanec == null)
				{
					prihlasenyZamestnanec = DataWorkspace.SpravaZmluvData.ZamestnanecPodlaLoginu(this.Application.User.Name);
				}
				return prihlasenyZamestnanec;
			}
		}

		public bool IsCurrentUserAdministrator
		{
			get
			{
				if (PrihlasenyZamestnanec != null && PrihlasenyZamestnanec.Rola != null)
				{
					return (PrihlasenyZamestnanec.Rola.Nazov == "administrator");
				}
				else
				{
					return false;
				}
			}
		}

		public bool IsCurrentUserPowerUser
		{
			get
			{
				if (PrihlasenyZamestnanec != null && PrihlasenyZamestnanec.Rola != null)
				{
					return (PrihlasenyZamestnanec.Rola.Nazov == "power user");
				}
				else
				{
					return false;
				}
			}
		}

		public bool Zmluvy_CanEdit
		{
			get
			{
				return IsCurrentUserAdministrator || IsCurrentUserPowerUser;
			}
		}

		partial void PracovneZaradenies_All_PreprocessQuery(ref IQueryable<PracovneZaradenie> query)
		{
			query = query.OrderBy(entity => entity.Nazov);
		}

		partial void Otazkas_All_PreprocessQuery(ref IQueryable<Otazka> query)
		{
			query = query.OrderBy(pz => pz.Znenie);
		}

		partial void SkolenieTyps_All_PreprocessQuery(ref IQueryable<SkolenieTyp> query)
		{
			query = query.OrderBy(entity => entity.Nazov);
		}

		partial void ZamestnanecPodlaLoginu_PreprocessQuery(string Login, ref IQueryable<Zamestnanec> query)
		{
			query = query.Where(z => z.Login.ToLower() == Login.ToLower());
		}

		partial void OtazkyPreSkolenie_PreprocessQuery(int? SkolenieTypID, int? SkoleniePreKohoID, ref IQueryable<Otazka> query)
		{
			int skolenieTypID = SkolenieTypID ?? -1;
			int skoleniePreKohoID = SkoleniePreKohoID ?? -1;
			query = query.Where(o =>
				skolenieTypID != -1 && skoleniePreKohoID != -1 &&
				o.SkolenieTypOtazkas.Select(sto => sto.SkolenieTyp.ID).Contains(skolenieTypID) &&
				o.SkoleniePreKohoOtazkas.Select(spko => spko.SkoleniePreKoho.ID).Contains(skoleniePreKohoID));
		}

		partial void Organizacie_All_PreprocessQuery(ref IQueryable<Organizacia> query)
		{
			query = query.OrderBy(entity => entity.Nazov);
		}

		partial void SkolenieDruhs_All_PreprocessQuery(ref IQueryable<SkolenieDruh> query)
		{
			query = query.OrderBy(entity => entity.Nazov);
		}

		partial void Zamestnanecs_All_PreprocessQuery(ref IQueryable<Zamestnanec> query)
		{
			query = query.OrderBy(entity => entity.Priezvisko + " " + entity.Meno);
		}

		partial void Zmluvy_All_PreprocessQuery(ref IQueryable<Zmluva> query)
		{
			query = query.OrderBy(entity => entity.Nazov);
		}

		partial void Portfolios_All_PreprocessQuery(ref IQueryable<Portfolio> query)
		{
			query = query.OrderBy(entity => entity.Nazov);
		}

		partial void OrganizacieSearch_PreprocessQuery(string searchString, ref IQueryable<Organizacia> query)
		{
			query = query.Where(o => o.Referencia == searchString);
			if (query.Count() != 1)
				query.Where(o => o.Nazov == searchString);
		}

		partial void PosluchacFromDb_PreprocessQuery(string meno, string priezvisko, string titul, int? organizaciaId, ref IQueryable<Posluchac> query)
		{
			query = query.Where(p =>
				(p.Meno == meno || p.Meno == null && meno == null)
				&&
				(p.Priezvisko == priezvisko || p.Priezvisko == null && priezvisko == null)
				&&
				(p.Titul == titul || p.Titul == null && titul == null)
				&&
				(p.Organizacia.ID == organizaciaId));
		}
	}
}
