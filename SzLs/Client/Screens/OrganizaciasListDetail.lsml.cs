using System.Linq;
using Microsoft.LightSwitch;
namespace LightSwitchApplication
{
	public partial class OrganizaciasListDetail
	{
		partial void OrganizaciasListDetail_Created()
		{
			// Write your code here.
			Konfiguracia predvolenyFilterStavOrganizacie = this.DataWorkspace.SpravaZmluvData
				.KonfiguracnaHodnota("PredvolenyFilterStavOrganizacie").FirstOrDefault();

			this.OrganizaciaStav = this.OrganizaciaStavs
				.FirstOrDefault(organizaciaStav => organizaciaStav.Nazov == predvolenyFilterStavOrganizacie.Hodnota);
		}

		partial void ZrusitFiltre_Execute()
		{
			// Write your code here.
			this.OrganizaciaStav = null;

		}
	}
}
