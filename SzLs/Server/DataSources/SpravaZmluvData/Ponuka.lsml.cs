namespace LightSwitchApplication
{
	public partial class Ponuka
	{
		partial void EmailSablona_Changed()
		{
			if (this.EmailSablona != null)
			{
				this.Subject = this.EmailSablona.Subject;
				this.TeloSpravy = this.EmailSablona.TeloSpravy;
			}
		}
	}
}