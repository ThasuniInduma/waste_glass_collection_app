using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using WasteGlassApi.Services;
using WasteGlassApi.Seed;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton(_ =>
{
    // Hosted environments pass the service account JSON as a secret env var.
    // Local dev falls back to the gitignored key file on disk.
    var credentialsJson = Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_JSON");
    Console.WriteLine(string.IsNullOrEmpty(credentialsJson)
        ? "FIREBASE_CREDENTIALS_JSON is NOT set - falling back to local firebase-key.json"
        : $"FIREBASE_CREDENTIALS_JSON is set ({credentialsJson.Length} chars) - using it");

    var credential      = !string.IsNullOrEmpty(credentialsJson)
        ? GoogleCredential.FromJson(credentialsJson)
        : GoogleCredential.FromFile(Path.Combine(Directory.GetCurrentDirectory(), "firebase-key.json"));

    return new FirestoreDbBuilder
    {
        ProjectId        = builder.Configuration["Firebase:ProjectId"],
        GoogleCredential = credential,
    }.Build();
});

builder.Services.AddSingleton<FirebaseService>();
builder.Services.AddSingleton<RouteService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader()
    );
});

builder.Services.AddControllers();

var app = builder.Build();

app.UseCors("AllowAll");
app.MapControllers();

var firebase = app.Services.GetRequiredService<FirebaseService>();
await new SeedData(firebase).RunAsync();

app.Run();