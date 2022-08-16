using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AnimeTickets.Migrations
{
    public partial class CharacterID : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "CharacterId",
                table: "Characters",
                newName: "Id");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Id",
                table: "Characters",
                newName: "CharacterId");
        }
    }
}
