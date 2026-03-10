using Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<University> Universities => Set<University>();
    public DbSet<Project> Projects => Set<Project>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    
    // Naye Chat Tables Add Kiye Hain
    public DbSet<ChatChannel> ChatChannels => Set<ChatChannel>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(e =>
        {
            e.HasIndex(u => u.Email).IsUnique();
            e.Property(u => u.Role).HasMaxLength(20);
        });
        modelBuilder.Entity<Project>(e =>
        {
            e.Property(p => p.Status).HasMaxLength(30);
            e.Property(p => p.ProgressPercent).HasPrecision(5, 2);
            e.Property(p => p.SimilarityScore).HasPrecision(5, 2);
        });
    }
}