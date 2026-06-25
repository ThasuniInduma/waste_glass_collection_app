using Google.Cloud.Firestore;
using WasteGlassApi.Models;

namespace WasteGlassApi.Services
{
    public class FirebaseService
    {
        private readonly FirestoreDb _db;

        public FirebaseService(FirestoreDb db)
        {
            _db = db;
        }

        // Get today's suppliers
        public async Task<List<Supplier>> GetTodaySuppliersAsync()
        {
            var today    = DateTime.UtcNow.ToString("yyyy-MM-dd");
            var snapshot = await _db.Collection("suppliers")
                                    .WhereEqualTo("tripDate", today)
                                    .GetSnapshotAsync();

            var list = new List<Supplier>();
            foreach (var doc in snapshot.Documents)
            {
                doc.TryGetValue<double>("collectedClearKg", out var collectedClearKg);
                doc.TryGetValue<double>("collectedColouredKg", out var collectedColouredKg);

                list.Add(new Supplier
                {
                    Id                  = doc.GetValue<string>("id"),
                    Name                = doc.GetValue<string>("name"),
                    Lat                 = doc.GetValue<double>("lat"),
                    Lng                 = doc.GetValue<double>("lng"),
                    ExpectedKg          = doc.GetValue<double>("expectedKg"),
                    BarcodeId           = doc.GetValue<string>("barcodeId"),
                    Status              = doc.GetValue<string>("status"),
                    StopOrder           = (int)doc.GetValue<long>("stopOrder"),
                    CollectedClearKg    = collectedClearKg,
                    CollectedColouredKg = collectedColouredKg,
                });
            }
            return list;
        }

        // Update supplier status and the quantities collected from them
        public async Task UpdateSupplierCollectionAsync(
            string supplierId, double clearKg, double colouredKg, string status)
        {
            var doc = _db.Collection("suppliers").Document(supplierId);
            await doc.UpdateAsync(new Dictionary<string, object>
            {
                { "status",              status },
                { "collectedClearKg",    clearKg },
                { "collectedColouredKg", colouredKg },
            });
        }

        // Save a collection record
        public async Task SaveCollectionAsync(CollectionRecord record)
        {
            await _db.Collection("collections").AddAsync(new Dictionary<string, object>
            {
                { "supplierId",  record.SupplierId },
                { "clearKg",     record.ClearKg },
                { "colouredKg",  record.ColouredKg },
                { "condition",   record.Condition },
                { "timestamp",   record.Timestamp },
                { "tripDate",    DateTime.UtcNow.ToString("yyyy-MM-dd") }
            });
        }

        // Get today's collections for trip summary
        public async Task<List<CollectionRecord>> GetTodayCollectionsAsync()
        {
            var today    = DateTime.UtcNow.ToString("yyyy-MM-dd");
            var snapshot = await _db.Collection("collections")
                                    .WhereEqualTo("tripDate", today)
                                    .GetSnapshotAsync();

            var list = new List<CollectionRecord>();
            foreach (var doc in snapshot.Documents)
            {
                list.Add(new CollectionRecord
                {
                    SupplierId = doc.GetValue<string>("supplierId"),
                    ClearKg    = doc.GetValue<double>("clearKg"),
                    ColouredKg = doc.GetValue<double>("colouredKg"),
                    Condition  = doc.GetValue<string>("condition"),
                    Timestamp  = doc.GetValue<string>("timestamp"),
                });
            }
            return list;
        }
        // Save a supplier document — used by seed only
        public async Task SaveSupplierAsync(Dictionary<string, object> supplier)
        {
            var docRef = _db.Collection("suppliers").Document(supplier["id"].ToString());
            await docRef.SetAsync(supplier);
        }
    }
}