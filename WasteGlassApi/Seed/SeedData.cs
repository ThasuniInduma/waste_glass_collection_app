using WasteGlassApi.Services;

namespace WasteGlassApi.Seed
{
    public class SeedData
    {
        private readonly FirebaseService _firebase;

        public SeedData(FirebaseService firebase)
        {
            _firebase = firebase;
        }

        public async Task RunAsync()
        {
            // Check if already seeded
            var existing = await _firebase.GetTodaySuppliersAsync();
            if (existing.Count > 0)
            {
                Console.WriteLine($"Already seeded — {existing.Count} suppliers found.");
                return;
            }

            Console.WriteLine("Seeding suppliers...");

            var today = DateTime.UtcNow.ToString("yyyy-MM-dd");

            var suppliers = new List<Dictionary<string, object>>
            {
                new() {
                    { "id",         "SUP001" },
                    { "name",       "Glass Hub Colombo" },
                    { "lat",        6.9271 },
                    { "lng",        79.8612 },
                    { "expectedKg", 50.0 },
                    { "barcodeId",  "SUP001" },
                    { "status",     "Pending" },
                    { "stopOrder",  0 },
                    { "tripDate",   today }
                },
                new() {
                    { "id",         "SUP002" },
                    { "name",       "Recycle King Nugegoda" },
                    { "lat",        6.8731 },
                    { "lng",        79.8892 },
                    { "expectedKg", 30.0 },
                    { "barcodeId",  "SUP002" },
                    { "status",     "Pending" },
                    { "stopOrder",  0 },
                    { "tripDate",   today }
                },
                new() {
                    { "id",         "SUP003" },
                    { "name",       "Green Collect Kandy" },
                    { "lat",        7.2906 },
                    { "lng",        80.6337 },
                    { "expectedKg", 45.0 },
                    { "barcodeId",  "SUP003" },
                    { "status",     "Pending" },
                    { "stopOrder",  0 },
                    { "tripDate",   today }
                },
                new() {
                    { "id",         "SUP004" },
                    { "name",       "EcoGlass Negombo" },
                    { "lat",        7.2081 },
                    { "lng",        79.8358 },
                    { "expectedKg", 60.0 },
                    { "barcodeId",  "SUP004" },
                    { "status",     "Pending" },
                    { "stopOrder",  0 },
                    { "tripDate",   today }
                },
                new() {
                    { "id",         "SUP005" },
                    { "name",       "Clear View Gampaha" },
                    { "lat",        7.0917 },
                    { "lng",        80.0000 },
                    { "expectedKg", 35.0 },
                    { "barcodeId",  "SUP005" },
                    { "status",     "Pending" },
                    { "stopOrder",  0 },
                    { "tripDate",   today }
                },
                new() {
                    { "id",         "SUP006" },
                    { "name",       "Southern Glass Galle" },
                    { "lat",        6.0535 },
                    { "lng",        80.2210 },
                    { "expectedKg", 40.0 },
                    { "barcodeId",  "SUP006" },
                    { "status",     "Pending" },
                    { "stopOrder",  0 },
                    { "tripDate",   today }
                },
                new() {
                    { "id",         "SUP007" },
                    { "name",       "Kalutara Bottle Bank" },
                    { "lat",        6.5854 },
                    { "lng",        79.9607 },
                    { "expectedKg", 25.0 },
                    { "barcodeId",  "SUP007" },
                    { "status",     "Pending" },
                    { "stopOrder",  0 },
                    { "tripDate",   today }
                },
            };

            foreach (var s in suppliers)
            {
                await _firebase.SaveSupplierAsync(s);
                Console.WriteLine($"  ✓ Seeded: {s["name"]}");
            }

            Console.WriteLine("Seeding complete!");
        }
    }
}