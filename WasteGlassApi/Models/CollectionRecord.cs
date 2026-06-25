namespace WasteGlassApi.Models
{
    public class CollectionRecord
    {
        public string SupplierId { get; set; } = "";
        public double ClearKg    { get; set; }
        public double ColouredKg { get; set; }
        public string Condition  { get; set; } = "";
        public string Timestamp  { get; set; } = "";
        public string TripDate   { get; set; } = DateTime.UtcNow.ToString("yyyy-MM-dd");
    }
}