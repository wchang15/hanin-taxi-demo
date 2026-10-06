using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KoreanTaxi.Migrations
{
    /// <inheritdoc />
    public partial class removenameuniqueindex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_companygooglelocations_name",
                table: "companygooglelocations");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "ix_companygooglelocations_name",
                table: "companygooglelocations",
                column: "name",
                unique: true);
        }
    }
}
