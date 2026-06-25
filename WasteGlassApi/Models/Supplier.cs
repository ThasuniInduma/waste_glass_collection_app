namespace WasteGlassApi.Models
{
    public class Supplier
    {
        public string Id              { get; set; } = "";
        public string Name            { get; set; } = "";
        public double Lat             { get; set; }
        public double Lng             { get; set; }
        public double ExpectedKg      { get; set; }
        public string BarcodeId       { get; set; } = "";
        public string Status          { get; set; } = "Pending";
        public int    StopOrder       { get; set; }
        public double CollectedClearKg    { get; set; }
        public double CollectedColouredKg { get; set; }
    }
}