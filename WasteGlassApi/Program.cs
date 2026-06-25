using Google.Cloud.Firestore;
using WasteGlassApi.Services;
using WasteGlassApi.Seed;

var builder = WebApplication.CreateBuilder(args);

Environment.SetEnvironmentVariable(
    "GOOGLE_APPLICATION_CREDENTIALS",
    Path.Combine(Directory.GetCurrentDirectory(), "firebase-key.json")
);

builder.Services.AddSingleton(_ =>
    FirestoreDb.Create(builder.Configuration["Firebase:ProjectId"])
);

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