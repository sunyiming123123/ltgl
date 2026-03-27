using Microsoft.EntityFrameworkCore;
using glxt.Models;

namespace glxt.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Friendship> Friendships { get; set; }
        public DbSet<ChatGroup> ChatGroups { get; set; }
        public DbSet<ChatGroupMember> ChatGroupMembers { get; set; }
        public DbSet<ChatMessage> ChatMessages { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            // 配置用户模型
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasIndex(u => u.Username).IsUnique();
                entity.HasIndex(u => u.Email).IsUnique();
            });

            // 配置好友关系
            modelBuilder.Entity<Friendship>(entity =>
            {
                // 确保同一对用户只能有一条好友关系记录
                entity.HasIndex(f => new { f.RequesterId, f.AddresseeId }).IsUnique();

                // 配置外键关系，防止级联删除
                entity.HasOne(f => f.Requester)
                    .WithMany()
                    .HasForeignKey(f => f.RequesterId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(f => f.Addressee)
                    .WithMany()
                    .HasForeignKey(f => f.AddresseeId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // 配置聊天群组
            modelBuilder.Entity<ChatGroup>(entity =>
            {
                entity.HasOne(g => g.Creator)
                    .WithMany()
                    .HasForeignKey(g => g.CreatorId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // 配置群组成员
            modelBuilder.Entity<ChatGroupMember>(entity =>
            {
                // 确保同一用户在同一群组中只能有一条记录
                entity.HasIndex(m => new { m.ChatGroupId, m.UserId }).IsUnique();

                entity.HasOne(m => m.ChatGroup)
                    .WithMany(g => g.Members)
                    .HasForeignKey(m => m.ChatGroupId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(m => m.User)
                    .WithMany()
                    .HasForeignKey(m => m.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // 配置聊天消息
            modelBuilder.Entity<ChatMessage>(entity =>
            {
                entity.HasIndex(m => m.SenderId);
                entity.HasIndex(m => m.ReceiverId);
                entity.HasIndex(m => m.ChatGroupId);
                entity.HasIndex(m => m.SentAt);

                entity.HasOne(m => m.Sender)
                    .WithMany()
                    .HasForeignKey(m => m.SenderId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(m => m.Receiver)
                    .WithMany()
                    .HasForeignKey(m => m.ReceiverId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(m => m.ChatGroup)
                    .WithMany(g => g.Messages)
                    .HasForeignKey(m => m.ChatGroupId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}