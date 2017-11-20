using Microsoft.LightSwitch;
using Microsoft.LightSwitch.Presentation;
using Microsoft.LightSwitch.Presentation.Extensions;
using Microsoft.LightSwitch.Threading;
using System.Collections.Specialized;
using System.Linq;
using System.Windows;
using System.Windows.Controls;

namespace LightSwitchApplication
{
	public partial class XlsxRows
	{
		private DataGrid dataGrid;
		partial void XlsxRows_Created()
		{
			this.FindControl("XlsxRows").ControlAvailable += XlsxRows_ControlAvailable;

		}

		private void XlsxRows_ControlAvailable(object sender, ControlAvailableEventArgs e)
		{
			this.dataGrid = e.Control as DataGrid;
			this.UpdateGrid();
		}

		partial void XlsxRows1_Changed(NotifyCollectionChangedEventArgs e)
		{
			this.UpdateGrid();
		}

		private void UpdateGrid()
		{
			if (this.dataGrid != null)
			{
				var xlsxRow = this.XlsxRows1.FirstOrDefault(r => r.IsHeader);

				if (xlsxRow != null)
				{
					var nonColumnCount = xlsxRow.Details.Properties.All()
						.Count(p => !p.Name.StartsWith("Column") && p.Name != "XlsxCells");
					foreach (var column in this.dataGrid.Columns)
					{
						var index = this.dataGrid.Columns.IndexOf(column);
						if (index >= nonColumnCount)
							Dispatchers.Main.BeginInvoke(() =>
							{
								column.Visibility = Visibility.Collapsed;
							});
					}

					this.Details.Dispatcher.BeginInvoke(() =>
					{
						var cells = xlsxRow.XlsxCells.ToArray();
						if (cells != null)
						{
							var i = 0;
							foreach (var cell in cells)
							{
								if (cell.Value != null)
									Dispatchers.Main.EnsureInvoke(() =>
									{
										this.dataGrid.Columns[i + nonColumnCount].Visibility = Visibility.Visible;
									}, true);

								i++;
							}
						}
					});
				}
			}
		}
	}
}