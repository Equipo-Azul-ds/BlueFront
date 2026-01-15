@optionalTypeArgs
Feature: Gestión de Usuarios por el Administrador

  Background:
    Given que el administrador ha iniciado sesión
    And existen usuarios registrados en el sistema

  Scenario: Visualizar lista de usuarios
    When abro la página de gestión de usuarios
    Then debería ver al usuario "Juan Perez" con el rol "Usuario"
    And debería ver al usuario "Admin Trivvy" con el rol "Administrador"

  Scenario: Cambiar el rol de un usuario a administrador
    When abro la página de gestión de usuarios
    And presiono el botón "Dar privilegios" del usuario "Juan Perez"
    And confirmo el cambio en el diálogo
    Then el usuario "Juan Perez" debería figurar como "Administrador"

    Scenario: Cambiar el estado de un usuario a bloqueado
      When abro la página de gestión de usuarios
      And presiono el botón "Bloquear" del usuario "Juan Perez"
      And confirmo el cambio en el diálogo
      Then el usuario "Juan Perez" debería figurar como "Bloqueado"